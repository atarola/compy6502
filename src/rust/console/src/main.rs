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

    let d = display::display_init(&spawner, eve_device, eve_pd).await;
    d.write32(EVE_RAM_DL, clear_color_rgb(0, 0, 255)).await;
    d.write32(EVE_RAM_DL + 4, clear(1, 1, 1)).await;
    d.write32(EVE_RAM_DL + 8, DL_DISPLAY).await;
    d.write8(REG_DLSWAP, EVE_DLSWAP_FRAME).await;

    loop {
        info!("led on!");
        led.set_high();
        Timer::after_secs(1).await;

        info!("led off!");
        led.set_low();
        Timer::after_secs(1).await;
    }
}
