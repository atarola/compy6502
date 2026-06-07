use embassy_executor::Executor;
use embassy_rp::Peri;
use embassy_rp::multicore::{Stack, spawn_core1};
use embassy_rp::pac;
use embassy_rp::peripherals::CORE1;
use static_cell::StaticCell;

use crate::graphics::GraphicsHandle;
use crate::text::TextHandle;

const CMD_READ_STATUS: u8 = 0x01;
const CMD_GET_CHAR: u8 = 0x20;
const CMD_PUT_CHAR: u8 = 0x21;
const CMD_SET_MODE: u8 = 0x30;

const MODE_TEXT: u8 = 0x00;
const MODE_GRAPHICS: u8 = 0x01;

enum State {
    Idle,
    SendStatus,
    SendChar,
    ReceiveChar,
    ReceiveMode,
}

static mut CORE1_STACK: Stack<4096> = Stack::new();

pub fn host_init(core1: Peri<'static, CORE1>, text: TextHandle, graphics: GraphicsHandle) {
    spawn_core1(core1, unsafe { &mut *(&raw mut CORE1_STACK) }, move || {
        static EXECUTOR: StaticCell<Executor> = StaticCell::new();
        EXECUTOR.init(Executor::new()).run(|spawner| {
            spawner.spawn(host_task(text, graphics)).unwrap();
        });
    });
}

#[embassy_executor::task]
async fn host_task(text: TextHandle, _graphics: GraphicsHandle) {
    for pin in 0..4usize {
        pac::IO_BANK0.gpio(pin).ctrl().write(|w| w.set_funcsel(1));
    }

    pac::SPI0.cr1().write(|w| {
        w.set_ms(false);
        w.set_sse(false);
    });

    pac::SPI0.cr0().write(|w| {
        w.set_dss(7);
        w.set_frf(0);
        w.set_spo(false);
        w.set_sph(false);
        w.set_scr(0);
    });

    pac::SPI0.cpsr().write(|w| w.set_cpsdvsr(2));

    pac::SPI0.cr1().write(|w| {
        w.set_ms(true);
        w.set_sse(true);
    });

    let mut state = State::Idle;
    let mut tx_byte: u8 = 0;
    let mut mode = MODE_TEXT;

    while !pac::SPI0.sr().read().tnf() {}
    pac::SPI0.dr().write(|w| w.set_data(0));

    loop {
        while !pac::SPI0.sr().read().rne() {}
        let rx = pac::SPI0.dr().read().data() as u8;

        (state, tx_byte) = match state {
            State::Idle => match rx {
                CMD_READ_STATUS => (State::SendStatus, 0),
                CMD_GET_CHAR => (State::SendChar, 0),
                CMD_PUT_CHAR => (State::ReceiveChar, 0),
                CMD_SET_MODE => (State::ReceiveMode, 0),
                _ => (State::Idle, 0),
            },

            State::SendStatus => (State::Idle, 0),

            State::SendChar => (State::Idle, 0),

            State::ReceiveChar => {
                if mode == MODE_TEXT {
                    text.put_char(rx).await;
                }
                (State::Idle, 0)
            }

            State::ReceiveMode => {
                mode = rx;
                (State::Idle, 0)
            }
        };

        while !pac::SPI0.sr().read().tnf() {}
        pac::SPI0.dr().write(|w| w.set_data(tx_byte as u16));
    }
}
