use embassy_executor::{Executor, Spawner};
use embassy_rp::multicore::{spawn_core1, Stack};
use embassy_rp::peripherals::{CORE1, PIN_0, PIN_1, PIN_2, PIN_3, PIO0};
use embassy_rp::pio::{Config, Direction as PioDirection, Pio, ShiftDirection};
use embassy_rp::Peri;
use static_cell::StaticCell;

use crate::keyboard::KeyboardHandle;
use crate::text::TextHandle;

const CMD_READ_STATUS: u8 = 0x01;
const CMD_GET_CHAR: u8 = 0x20;
const CMD_PUT_CHAR: u8 = 0x21;
const CMD_SET_MODE: u8 = 0x30;

const MODE_TEXT: u8 = 0x00;
const MODE_GRAPHICS: u8 = 0x01;

enum State {
    Idle,
    ReceiveChar,
    ReceiveMode,
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
                pull block
                wait 0 gpio 1
            byte:
                set x, 7
            bitloop:
                out pins, 1
                wait 1 gpio 2
                in pins, 1
                wait 0 gpio 2
                jmp x-- bitloop
                push
                jmp pin capture
                pull block
                jmp byte
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
    cfg.shift_out.direction = ShiftDirection::Left;
    cfg.use_program(&prg, &[]);
    sm.set_config(&cfg);
    sm.tx().push(0);
    sm.set_enable(true);

    let mut state = State::Idle;
    let mut mode = MODE_TEXT;

    loop {
        let rx = (sm.rx().wait_pull().await & 0xff) as u8;
        let mut next_tx = 0u8;
        let mut put_char = None;
        let mut set_mode = None;

        match state {
            State::Idle => match rx {
                0x00 => {}
                CMD_READ_STATUS => {
                    next_tx = 0;
                }
                CMD_GET_CHAR => {
                    let c = KeyboardHandle::new().get_char().await.unwrap_or(0);
                    next_tx = c;
                }
                CMD_PUT_CHAR => {
                    state = State::ReceiveChar;
                }
                CMD_SET_MODE => {
                    state = State::ReceiveMode;
                }
                _ => {
                    state = State::Idle;
                }
            },

            State::ReceiveChar => {
                put_char = Some(rx);
                state = State::Idle;
            }

            State::ReceiveMode => {
                set_mode = Some(rx);
                state = State::Idle;
            }
        };

        sm.tx().wait_push((next_tx as u32) << 24).await;

        if let Some(c) = put_char {
            if mode == MODE_TEXT {
                TextHandle::new().put_char(c).await;
            }
            if c != 0 {
                log::info!("console char 0x{:02x}", c);
            }
        }

        if let Some(new_mode) = set_mode {
            mode = new_mode;
        }
    }
}
