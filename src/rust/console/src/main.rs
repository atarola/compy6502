#![no_std]
#![no_main]

mod display;
mod eve;
mod graphics;
mod host;
mod text;

use crate::eve::*;
use defmt::*;
use embassy_embedded_hal::shared_bus::asynch::spi::SpiDeviceWithConfig;
use embassy_executor::Spawner;
use embassy_rp::gpio::{Level, Output};
use embassy_rp::peripherals::SPI1;
use embassy_rp::spi::{Async, Config, Spi};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::mutex::Mutex;
use embassy_time::Timer;
use static_cell::StaticCell;

use {defmt_rtt as _, panic_probe as _};

static SPI1_BUS: StaticCell<Mutex<CriticalSectionRawMutex, Spi<'static, SPI1, Async>>> =
    StaticCell::new();

#[embassy_executor::main]
async fn main(spawner: Spawner) {
    let p = embassy_rp::init(Default::default());

    let spi1 = Spi::new(
        p.SPI1,
        p.PIN_14,
        p.PIN_15,
        p.PIN_8,
        p.DMA_CH0,
        p.DMA_CH1,
        Config::default(),
    );

    let spi1_bus = SPI1_BUS.init(Mutex::new(spi1));

    let eve_cs = Output::new(p.PIN_9, Level::High);
    let eve_pd = Output::new(p.PIN_6, Level::High);
    let eve_device = SpiDeviceWithConfig::new(spi1_bus, eve_cs, Config::default());

    let mut led = Output::new(p.PIN_13, Level::Low);

    display::display_init(&spawner, eve_device, eve_pd).await;
    text::text_init(&spawner, display::DisplayHandle::new()).await;
    host::host_init(
        p.CORE1,
        text::TextHandle::new(),
        graphics::GraphicsHandle::new(),
    );

    loop {
        led.set_high();
        Timer::after_millis(500).await;
        led.set_low();
        Timer::after_millis(500).await;
    }
}
