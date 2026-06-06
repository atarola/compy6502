use embassy_executor::Spawner;
use embassy_rp::gpio::Output;
use embassy_rp::peripherals::{DMA_CH0, DMA_CH1, PIN_6, PIN_8, PIN_9, PIN_14, PIN_15, SPI1};
use embassy_rp::spi::{Async, Spi};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::{Channel, Sender};

static DISPLAY_CHANNEL: Channel<CriticalSectionRawMutex, DisplayCmd, 32> = Channel::new();

type DisplaySender = Sender<'static, CriticalSectionRawMutex, DisplayCmd, 32>;

pub enum DisplayCmd {
    Cmd(u8),
    Write8(u32, u8),
    Write16(u32, u16),
    Write32(u32, u32),
}

pub struct EveDriver(DisplaySender);

impl EveDriver {
    pub async fn cmd(&self, cmd: u8) { todo!() }
    pub async fn write8(&self, addr: u32, data: u8) { todo!() }
    pub async fn write16(&self, addr: u32, data: u16) { todo!() }
    pub async fn write32(&self, addr: u32, data: u32) { todo!() }
}

pub async fn display_init(
    spawner: &Spawner,
    spi: SPI1,
    sck: PIN_14,
    mosi: PIN_15,
    miso: PIN_8,
    tx_dma: DMA_CH0,
    rx_dma: DMA_CH1,
    cs: PIN_9,
    pd: PIN_6,
) -> EveDriver { todo!() }

#[embassy_executor::task]
async fn display_task(
    mut spi: Spi<'static, SPI1, Async>,
    mut cs: Output<'static>,
    mut pd: Output<'static>,
) { todo!() }

fn encode_addr(buf: &mut [u8], addr: u32, write: bool) { todo!() }
fn encode_data(buf: &mut [u8], data: u32, len: usize) { todo!() }

async fn eve_init(
    spi: &mut Spi<'static, SPI1, Async>,
    cs: &mut Output<'static>,
    pd: &mut Output<'static>,
) { todo!() }
