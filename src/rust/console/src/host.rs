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
const STATUS_KEYBOARD_READY: u8 = 0x01;
const STATUS_HOST_READY: u8 = 0x02;
const CS_LOW_MARKER: u32 = u32::MAX;
const CS_HIGH_MARKER: u32 = u32::MAX - 1;
const HOST_TXN_QUEUE_DEPTH: usize = 64;
const HOST_TXN_CAPACITY: usize = 32;
const HOST_READY_FREE_SLOTS: u32 = 8;

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

    pub fn as_slice(&self) -> &[u8] {
        &self.buf
    }
}

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
    match buf.buf.first().copied() {
        Some(CMD_READ_STATUS | CMD_GET_CHAR) | None => return,
        _ => {}
    }

    if let Some(txn) = HostTxn::from_buffer(buf) {
        let _ = HOST_TXN_CHANNEL.try_send(txn);
    }
}

pub async fn receive_txn() -> HostTxn {
    HOST_TXN_CHANNEL.receive().await
}

pub fn try_receive_txn() -> Option<HostTxn> {
    HOST_TXN_CHANNEL.try_receive().ok()
}

fn status_byte() -> u8 {
    let mut status = 0;

    if KeyboardHandle::new().has_data() {
        status |= STATUS_KEYBOARD_READY;
    }
    let queued = HOST_TXN_CHANNEL.len() as u32;
    if (HOST_TXN_QUEUE_DEPTH as u32).saturating_sub(queued) >= HOST_READY_FREE_SLOTS {
        status |= STATUS_HOST_READY;
    }

    status
}

async fn next_response(rx: u8, txn_buf: &CommandBuffer) -> u8 {
    if !txn_buf.buf.is_empty() {
        return 0;
    }

    match rx {
        CMD_READ_STATUS => {
            status_byte()
        }
        CMD_GET_CHAR => {
            KeyboardHandle::new().get_char().await.unwrap_or(0)
        }
        _ => 0,
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
        });
    });
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
                pull block
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
        let word = match select(sm.rx().wait_pull(), Timer::after_micros(10)).await {
            Either::First(word) => word,
            Either::Second(_) => {
                poll_cs_edges(&mut cs_sm, &mut txn_buf, &mut in_txn, &mut txn_done);
                if txn_done {
                    drain_spi_rx(&mut sm, &mut txn_buf, in_txn);
                    enqueue_txn(&txn_buf);
                    txn_buf.clear();
                    in_txn = false;
                    txn_done = false;
                }
                continue;
            }
        };
        poll_cs_edges(&mut cs_sm, &mut txn_buf, &mut in_txn, &mut txn_done);

        let rx = decode_rx(word);
        if !in_txn && !txn_done {
            txn_buf.clear();
            in_txn = true;
        }
        let next_tx = next_response(rx, &txn_buf).await;

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
