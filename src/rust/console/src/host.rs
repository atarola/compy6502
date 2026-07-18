use embassy_executor::{Executor, Spawner};
use embassy_futures::select::{Either, select};
use embassy_rp::Peri;
use embassy_rp::multicore::{Stack, spawn_core1};
use embassy_rp::peripherals::{CORE1, PIN_0, PIN_1, PIN_2, PIN_3, PIO0};
use embassy_rp::pio::{Config, Direction as PioDirection, Pio, ShiftDirection};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::Channel;
use embassy_time::Timer;
use heapless::Vec;
use static_cell::StaticCell;

use crate::keyboard::KeyboardHandle;

const CMD_READ_STATUS: u8 = 0x01;
const CMD_GET_CHAR: u8 = 0x20;
const CMD_WAKEUP: u8 = 0x5A;
const CS_LOW_MARKER: u32 = u32::MAX;
const CS_HIGH_MARKER: u32 = u32::MAX - 1;
const HOST_TXN_QUEUE_DEPTH: usize = 4;
const HOST_TXN_CAPACITY: usize = 256;

static HOST_TXN_CHANNEL: Channel<CriticalSectionRawMutex, HostTxn, HOST_TXN_QUEUE_DEPTH> =
    Channel::new();

pub struct HostTxn {
    buf: Vec<u8, HOST_TXN_CAPACITY>,
}

impl HostTxn {
    fn from_buffer(buf: &CommandBuffer) -> Option<HostTxn> {
        let mut txn = HostTxn { buf: Vec::new() };
        txn.buf.extend_from_slice(&buf.buf).ok()?;
        Some(txn)
    }

    fn opcode(&self) -> Option<u8> {
        self.buf.first().copied()
    }

    fn len(&self) -> usize {
        self.buf.len()
    }
}

const EXPECTED_TXNS: &[(u8, usize)] = &[
    (0xA1, 1),
    (0xB1, 2),
    (0xC1, 3),
    (0xD1, 4),
    (0xE1, 8),
    (0xF1, 16),
];

pub struct CommandBuffer {
    buf: Vec<u8, HOST_TXN_CAPACITY>,
    len: u8,
}

impl CommandBuffer {
    fn new() -> CommandBuffer {
        CommandBuffer {
            buf: Vec::new(),
            len: 0,
        }
    }

    fn clear(&mut self) {
        self.buf.clear();
        self.len = 0;
    }

    fn push(&mut self, byte: u8) {
        if self.buf.push(byte).is_ok() {
            self.len = self.len.saturating_add(1);
        }
    }
}

fn decode_rx(word: u32) -> u8 {
    (word & 0xff) as u8
}

fn enqueue_txn(buf: &CommandBuffer) {
    if let Some(txn) = HostTxn::from_buffer(buf) {
        if HOST_TXN_CHANNEL.try_send(txn).is_err() {
            log::info!("host: txn queue full len={}", buf.len);
        }
    }
}

fn poll_cs_edges(
    cs_sm: &mut embassy_rp::pio::StateMachine<'_, embassy_rp::peripherals::PIO0, 1>,
    txn_buf: &mut CommandBuffer,
    in_txn: &mut bool,
    txn_done: &mut bool,
) {
    while let Some(word) = cs_sm.rx().try_pull() {
        match word {
            CS_LOW_MARKER => {
                txn_buf.clear();
                *in_txn = true;
                *txn_done = false;
            }
            CS_HIGH_MARKER => {
                *txn_done = true;
            }
            _ => {}
        }
    }
}

fn drain_spi_rx(
    sm: &mut embassy_rp::pio::StateMachine<'_, embassy_rp::peripherals::PIO0, 0>,
    txn_buf: &mut CommandBuffer,
    in_txn: bool,
) {
    while let Some(word) = sm.rx().try_pull() {
        let rx = decode_rx(word);
        if in_txn {
            txn_buf.push(rx);
        }
    }
}

static mut CORE1_STACK: Stack<4096> = Stack::new();

pub fn host_init(
    _spawner: Spawner,
    core1: Peri<'static, CORE1>,
    pio0: Pio<'static, PIO0>,
    pin_miso: Peri<'static, PIN_0>,
    pin_cs: Peri<'static, PIN_1>,
    pin_sck: Peri<'static, PIN_2>,
    pin_mosi: Peri<'static, PIN_3>,
) {
    spawn_core1(core1, unsafe { &mut *(&raw mut CORE1_STACK) }, move || {
        static EXECUTOR: StaticCell<Executor> = StaticCell::new();
        EXECUTOR.init(Executor::new()).run(|spawner| {
            spawner
                .spawn(pio_task(pio0, pin_miso, pin_cs, pin_sck, pin_mosi))
                .unwrap();
            spawner.spawn(host_task()).unwrap();
        });
    });
}

#[embassy_executor::task]
async fn host_task() {
    let receiver = HOST_TXN_CHANNEL.receiver();
    let mut expected = 0usize;
    let mut locked = false;
    let mut total = 0u32;
    let mut errors = 0u32;
    log::info!("host: txn consumer start");

    loop {
        let txn = receiver.receive().await;
        total = total.wrapping_add(1);

        if let Some(opcode) = txn.opcode() {
            if opcode == CMD_WAKEUP && txn.len() == 1 {
                expected = 0;
                if !locked {
                    log::info!("host: txn validator locked total={}", total);
                }
                locked = true;
                continue;
            }

            if !locked {
                continue;
            }

            let observed = EXPECTED_TXNS
                .iter()
                .enumerate()
                .find(|(_, (op, len))| opcode == *op && txn.len() == *len)
                .map(|(idx, _)| idx);

            match observed {
                Some(idx) if idx == expected => {
                    expected = (idx + 1) % EXPECTED_TXNS.len();
                }
                Some(_) => {
                    errors = errors.wrapping_add(1);
                    let (expected_opcode, expected_len) = EXPECTED_TXNS[expected];
                    log::info!(
                        "host: txn sequence mismatch got opcode=0x{:02X} len={} expected opcode=0x{:02X} len={}",
                        opcode,
                        txn.len(),
                        expected_opcode,
                        expected_len
                    );
                    locked = false;
                    expected = 0;
                }
                None => {
                    errors = errors.wrapping_add(1);
                    log::info!(
                        "host: txn shape mismatch got opcode=0x{:02X} len={}",
                        opcode,
                        txn.len()
                    );
                    locked = false;
                    expected = 0;
                }
            }
        }

        if total % 1024 == 0 {
            log::info!("host: txn summary total={} errors={}", total, errors);
        }
    }
}

#[embassy_executor::task]
async fn pio_task(
    pio: Pio<'static, PIO0>,
    pin_miso: Peri<'static, PIN_0>,
    pin_cs: Peri<'static, PIN_1>,
    pin_sck: Peri<'static, PIN_2>,
    pin_mosi: Peri<'static, PIN_3>,
) {
    let spi_prg = ::pio::pio_asm!(
        r#"
            init:
                pull block
                mov isr, null
                wait 1 gpio 1
            capture:
                wait 0 gpio 1
                set x, 7
                jmp bitloop
            byte:
                jmp pin flush
                set x, 7
            bitloop:
                out pins, 1
                wait 1 gpio 2
                in pins, 1
                jmp pin flush
                wait 0 gpio 2
                jmp x-- bitloop
                push
                pull noblock
                jmp byte
            flush:
                mov isr, null
                jmp capture
        "#
    );
    let cs_prg = ::pio::pio_asm!(
        r#"
            init:
                wait 1 gpio 1
            low:
                wait 0 gpio 1
                mov isr, ~null
                push noblock
            high:
                wait 1 gpio 1
                mov isr, ~null
                in null, 1
                push noblock
                jmp low
        "#
    );

    let mut common = pio.common;
    let mut sm = pio.sm0;
    let mut cs_sm = pio.sm1;
    let pin_miso = common.make_pio_pin(pin_miso);
    let pin_cs = common.make_pio_pin(pin_cs);
    let pin_sck = common.make_pio_pin(pin_sck);
    let pin_mosi = common.make_pio_pin(pin_mosi);
    let spi_prg = common.load_program(&spi_prg.program);
    let cs_prg = common.load_program(&cs_prg.program);

    sm.set_pin_dirs(PioDirection::Out, &[&pin_miso]);
    sm.set_pin_dirs(PioDirection::In, &[&pin_cs, &pin_sck, &pin_mosi]);

    let mut cfg = Config::default();
    cfg.set_in_pins(&[&pin_mosi]);
    cfg.set_out_pins(&[&pin_miso]);
    cfg.set_jmp_pin(&pin_cs);
    cfg.shift_in.direction = ShiftDirection::Left;
    cfg.shift_out.direction = ShiftDirection::Left;
    cfg.use_program(&spi_prg, &[]);
    sm.set_config(&cfg);
    sm.tx().push(0);
    sm.set_enable(true);

    let mut cs_cfg = Config::default();
    cs_cfg.shift_in.direction = ShiftDirection::Left;
    cs_cfg.use_program(&cs_prg, &[]);
    cs_sm.set_config(&cs_cfg);
    cs_sm.set_enable(true);

    let mut txn_buf = CommandBuffer::new();
    let mut in_txn = false;
    let mut txn_done = false;

    loop {
        poll_cs_edges(&mut cs_sm, &mut txn_buf, &mut in_txn, &mut txn_done);
        if txn_done {
            drain_spi_rx(&mut sm, &mut txn_buf, in_txn);
            enqueue_txn(&txn_buf);
            txn_buf.clear();
            in_txn = false;
            txn_done = false;
            continue;
        }

        let word = match select(sm.rx().wait_pull(), Timer::after_micros(10)).await {
            Either::First(word) => word,
            Either::Second(_) => continue,
        };
        poll_cs_edges(&mut cs_sm, &mut txn_buf, &mut in_txn, &mut txn_done);

        let rx = decode_rx(word);
        let mut next_tx = 0u8;
        if !in_txn && !txn_done {
            txn_buf.clear();
            in_txn = true;
        }
        if txn_buf.buf.is_empty() {
            match rx {
                CMD_READ_STATUS => {
                    next_tx = KeyboardHandle::new().has_data() as u8;
                }
                CMD_GET_CHAR => {
                    next_tx = KeyboardHandle::new().get_char().await.unwrap_or(0);
                }
                _ => {}
            }
        }

        if in_txn || txn_done {
            txn_buf.push(rx);
            if txn_done {
                enqueue_txn(&txn_buf);
                txn_buf.clear();
                in_txn = false;
                txn_done = false;
            }
        }
        sm.tx().wait_push((next_tx as u32) << 24).await;
    }
}
