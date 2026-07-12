use embassy_executor::{Executor, Spawner};
use embassy_rp::multicore::{spawn_core1, Stack};
use embassy_rp::peripherals::{CORE1, PIN_0, PIN_1, PIN_2, PIN_3, PIO0};
use embassy_rp::pio::{Config, Direction as PioDirection, Pio, ShiftDirection};
use embassy_rp::Peri;
use static_cell::StaticCell;

use crate::keyboard::KeyboardHandle;
use crate::modes::ModeHandle;

const CMD_READ_STATUS: u8 = 0x01;
const CMD_GET_CHAR: u8 = 0x02;
const TXN_START: u32 = u32::MAX;
const TXN_END: u32 = u32::MAX - 1;

enum TxnState {
    Idle,
    AwaitOpcode,
    Mode,
    ReadStatus,
    GetChar,
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
            spawner.spawn(host_task(pio0, pin_miso, pin_cs, pin_sck, pin_mosi)).unwrap();
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
    let prg = ::pio::pio_asm!(
        r#"
            capture:
                wait 0 gpio 1
                set x, 0
                mov isr, invert(x)
                push
            byte:
                set x, 7
            bitloop:
                jmp pin end_txn
                wait 1 gpio 2
                in pins, 1
                wait 0 gpio 2
                out pins, 1
                jmp x-- bitloop
                jmp byte
            end_txn:
                wait 1 gpio 1
                set x, 1
                mov isr, invert(x)
                push
                jmp capture
        "#
    );

    let mut common = pio.common;
    let mut sm = pio.sm0;
    let pin_miso = common.make_pio_pin(pin_miso);
    let pin_cs = common.make_pio_pin(pin_cs);
    let pin_sck = common.make_pio_pin(pin_sck);
    let pin_mosi = common.make_pio_pin(pin_mosi);
    let prg = common.load_program(&prg.program);

    sm.set_pin_dirs(PioDirection::Out, &[&pin_miso]);
    sm.set_pin_dirs(PioDirection::In, &[&pin_cs, &pin_sck, &pin_mosi]);

    let mut cfg = Config::default();
    cfg.set_in_pins(&[&pin_mosi]);
    cfg.set_out_pins(&[&pin_miso]);
    cfg.set_jmp_pin(&pin_cs);
    cfg.shift_in.direction = ShiftDirection::Left;
    cfg.shift_in.threshold = 8;
    cfg.shift_in.auto_fill = true;
    cfg.shift_out.direction = ShiftDirection::Left;
    cfg.shift_out.threshold = 8;
    cfg.shift_out.auto_fill = true;
    cfg.use_program(&prg, &[]);
    sm.set_config(&cfg);
    sm.set_enable(true);

    let modes = ModeHandle::new();
    let mut txn_state = TxnState::Idle;

    loop {
        let rx = sm.rx().wait_pull().await;
        let mut next_tx = 0u8;

        match rx {
            TXN_START => {
                txn_state = TxnState::AwaitOpcode;
                modes.start_txn().await;
            }
            TXN_END => {
                txn_state = TxnState::Idle;
                modes.end_txn().await;
            }
            _ => {
                match txn_state {
                    TxnState::AwaitOpcode => match rx as u8 {
                        CMD_READ_STATUS => {
                            txn_state = TxnState::ReadStatus;
                        }
                        CMD_GET_CHAR => {
                            txn_state = TxnState::GetChar;
                            next_tx = KeyboardHandle::new().get_char().await.unwrap_or(0);
                        }
                        byte => {
                            txn_state = TxnState::Mode;
                            modes.consume(byte).await;
                        }
                    },
                    TxnState::Mode => {
                        modes.consume(rx as u8).await;
                    }
                    TxnState::ReadStatus => {
                        next_tx = 0;
                    }
                    TxnState::GetChar => {}
                    TxnState::Idle => {}
                }
            }
        }

        sm.tx().wait_push((next_tx as u32) << 24).await;
    }
}
