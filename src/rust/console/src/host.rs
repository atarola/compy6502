use embassy_executor::{Executor, Spawner};
use embassy_futures::select::{Either, select};
use embassy_rp::Peri;
use embassy_rp::multicore::{Stack, spawn_core1};
use embassy_rp::peripherals::{CORE1, PIN_0, PIN_1, PIN_2, PIN_3, PIO0};
use embassy_rp::pio::{Config, Direction as PioDirection, Pio, ShiftDirection};
use embassy_time::Timer;
use heapless::Vec;
use static_cell::StaticCell;

use crate::keyboard::KeyboardHandle;
use crate::modes::ModeHandle;

const CMD_READ_STATUS: u8 = 0x01;
const CMD_GET_CHAR: u8 = 0x20;
const CMD_SWITCH_MODE: u8 = 0xFF;
const CS_LOW_MARKER: u32 = u32::MAX;
const CS_HIGH_MARKER: u32 = u32::MAX - 1;
const LOG_RAW_SPI: bool = false;

pub struct CommandBuffer {
    pub buf: Vec<u8, 256>,
    pub len: u8,
}

impl CommandBuffer {
    pub fn new() -> CommandBuffer {
        CommandBuffer {
            buf: Vec::new(),
            len: 0,
        }
    }

    pub fn clear(&mut self) {
        self.buf.clear();
        self.len = 0;
    }

    pub fn push(&mut self, byte: u8) {
        if self.buf.push(byte).is_ok() {
            self.len = self.len.saturating_add(1);
        }
    }
}

fn decode_rx(word: u32) -> u8 {
    (word & 0xff) as u8
}

fn log_txn(buf: &CommandBuffer) {
    log::info!("host: cs edge low");
    for byte in buf.buf.iter() {
        log::info!("host: rx 0x{:02X}", byte);
    }
    log::info!("host: cs edge high");
}

async fn dispatch_txn(buf: &CommandBuffer, mode_handle: &ModeHandle) {
    let Some(&opcode) = buf.buf.first() else {
        return;
    };

    match opcode {
        0x00 | CMD_READ_STATUS | CMD_GET_CHAR => {}
        CMD_SWITCH_MODE => {
            log::info!("host: dispatch switch txn len={}", buf.len);
            if buf.buf.len() >= 2 {
                mode_handle.switch_mode(buf.buf[1]).await;
            } else {
                log::info!("host: short switch mode txn");
            }
        }
        _ => {
            log::info!(
                "host: dispatch mode txn opcode=0x{:02X} len={}",
                opcode,
                buf.len
            );
            mode_handle.start_txn().await;
            for &byte in buf.buf.iter() {
                mode_handle.consume(byte).await;
            }
            mode_handle.end_txn().await;
        }
    }
}

async fn drain_spi_rx(
    sm: &mut embassy_rp::pio::StateMachine<'_, embassy_rp::peripherals::PIO0, 0>,
    txn_buf: &mut CommandBuffer,
    in_txn: bool,
) {
    while let Some(word) = sm.rx().try_pull() {
        let rx = decode_rx(word);
        if in_txn {
            txn_buf.push(rx);
        } else {
            log::info!("host: rx outside txn 0x{:02X}", rx);
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
            _ => log::info!("host: cs marker 0x{:08X}", word),
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
                .spawn(host_task(pio0, pin_miso, pin_cs, pin_sck, pin_mosi))
                .unwrap();
        });
    });
}

#[embassy_executor::task]
async fn host_task(
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

    let mode_handle = ModeHandle::new();
    let mut txn_buf = CommandBuffer::new();
    let mut in_txn = false;
    let mut txn_done = false;

    loop {
        poll_cs_edges(&mut cs_sm, &mut txn_buf, &mut in_txn, &mut txn_done);
        if txn_done {
            Timer::after_micros(100).await;
            drain_spi_rx(&mut sm, &mut txn_buf, in_txn).await;
            if LOG_RAW_SPI {
                log_txn(&txn_buf);
            } else {
                dispatch_txn(&txn_buf, &mode_handle).await;
            }
            txn_buf.clear();
            in_txn = false;
            txn_done = false;
            continue;
        }

        let word = match select(sm.rx().wait_pull(), Timer::after_micros(100)).await {
            Either::First(word) => word,
            Either::Second(_) => continue,
        };
        poll_cs_edges(&mut cs_sm, &mut txn_buf, &mut in_txn, &mut txn_done);
        if !in_txn && !txn_done {
            Timer::after_micros(100).await;
            poll_cs_edges(&mut cs_sm, &mut txn_buf, &mut in_txn, &mut txn_done);
        }

        let rx = decode_rx(word);
        if LOG_RAW_SPI {
            if in_txn {
                txn_buf.push(rx);
            } else {
                log::info!("host: rx 0x{:02X}", rx);
            }
            if in_txn && !txn_done {
                Timer::after_micros(100).await;
                poll_cs_edges(&mut cs_sm, &mut txn_buf, &mut in_txn, &mut txn_done);
            }
            if txn_done {
                log_txn(&txn_buf);
                txn_buf.clear();
                in_txn = false;
                txn_done = false;
            }
            sm.tx().wait_push(0).await;
            continue;
        }

        let mut next_tx = 0u8;
        if !in_txn && !txn_done {
            txn_buf.clear();
            in_txn = true;
        }
        if (in_txn || txn_done) && txn_buf.buf.is_empty() {
            match rx {
                CMD_READ_STATUS => {
                    next_tx = KeyboardHandle::new().has_data() as u8;
                    log::info!("host: read status -> {}", next_tx);
                }
                CMD_GET_CHAR => {
                    next_tx = KeyboardHandle::new().get_char().await.unwrap_or(0);
                    log::info!("host: get char -> 0x{:02X}", next_tx);
                }
                _ => {}
            }
        }
        if in_txn || txn_done {
            txn_buf.push(rx);
            if txn_done {
                dispatch_txn(&txn_buf, &mode_handle).await;
                txn_buf.clear();
                in_txn = false;
                txn_done = false;
            }
        } else {
            log::info!("host: rx outside txn 0x{:02X}", rx);
        }
        sm.tx().wait_push((next_tx as u32) << 24).await;
    }
}
