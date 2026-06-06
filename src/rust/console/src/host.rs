use embassy_executor::Spawner;
use embassy_rp::peripherals::{PIN_0, PIN_1, PIN_2, PIN_3, SPI0};
use embassy_rp::spi::{Async, Spi};

use crate::graphics::GraphicsHandle;
use crate::text::TextHandle;

const CMD_NOP: u8         = 0x00;
const CMD_READ_STATUS: u8 = 0x01;
const CMD_GET_CHAR: u8    = 0x20;
const CMD_PUT_CHAR: u8    = 0x21;
const CMD_SET_MODE: u8    = 0x30;

const MODE_TEXT: u8     = 0x00;
const MODE_GRAPHICS: u8 = 0x01;

const STATUS_KBD_READY: u8 = 0x01;

enum State {
    Idle,
    SendStatus,
    SendChar,
    ReceiveChar,
    ReceiveMode,
}

enum ActiveHandle {
    Text(TextHandle),
    Graphics(GraphicsHandle),
}

pub async fn host_init(
    spawner: &Spawner,
    spi: SPI0,
    miso: PIN_0,
    sck: PIN_2,
    mosi: PIN_3,
    cs: PIN_1,
    text: TextHandle,
    graphics: GraphicsHandle,
) { todo!() }

#[embassy_executor::task]
async fn host_task(
    mut spi: Spi<'static, SPI0, Async>,
    text: TextHandle,
    graphics: GraphicsHandle,
) { todo!() }
