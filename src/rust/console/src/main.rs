#![no_std]
#![no_main]

mod display;
mod eve;
mod host;
mod keyboard;
mod keymap;
mod max3421e;
mod modes;

use crate::eve::*;
use defmt::*;
use embassy_embedded_hal::shared_bus::asynch::spi::SpiDeviceWithConfig;
use embassy_executor::Spawner;
use embassy_rp::bind_interrupts;
use embassy_rp::gpio::{Level, Output};
use embassy_rp::peripherals::{PIO0, SPI1, USB};
use embassy_rp::pio::{InterruptHandler as PioInterruptHandler, Pio};
use embassy_rp::spi::{Async, Config, Spi};
use embassy_rp::usb::{Driver, InterruptHandler};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::mutex::Mutex;
use embassy_time::Timer;
use embassy_usb_logger::{DummyHandler, LoggerState, UsbLogger};
use static_cell::StaticCell;

use {defmt_rtt as _, panic_probe as _};

bind_interrupts!(struct Irqs {
    PIO0_IRQ_0 => PioInterruptHandler<PIO0>;
    USBCTRL_IRQ => InterruptHandler<USB>;
});

static USB_LOGGER: UsbLogger<1024, DummyHandler> = UsbLogger::new();
static LOGGER_STATE: StaticCell<LoggerState<'static>> = StaticCell::new();

#[embassy_executor::task]
async fn usb_logger_task(state: &'static mut LoggerState<'static>, driver: Driver<'static, USB>) {
    USB_LOGGER.run(state, driver).await;
}

#[embassy_executor::task]
async fn blink_task(mut led: Output<'static>) {
    loop {
        led.set_high();
        Timer::after_millis(500).await;
        led.set_low();
        Timer::after_millis(500).await;
    }
}

static SPI1_BUS: StaticCell<Mutex<CriticalSectionRawMutex, Spi<'static, SPI1, Async>>> =
    StaticCell::new();

#[embassy_executor::main]
async fn main(spawner: Spawner) {
    let p = embassy_rp::init(Default::default());
    let pio0 = Pio::new(p.PIO0, Irqs);

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

    let usb_driver = Driver::new(p.USB, Irqs);
    let logger_state = LOGGER_STATE.init(LoggerState::new());

    unsafe {
        log::set_logger_racy(&USB_LOGGER).unwrap();
        log::set_max_level_racy(log::LevelFilter::Info);
    }

    spawner
        .spawn(usb_logger_task(logger_state, usb_driver))
        .unwrap();

    let eve_cs = Output::new(p.PIN_29, Level::High);
    let eve_pd = Output::new(p.PIN_6, Level::High);
    let eve_device = SpiDeviceWithConfig::new(spi1_bus, eve_cs, Config::default());

    let max_cs = Output::new(p.PIN_10, Level::High);
    let max_device = SpiDeviceWithConfig::new(spi1_bus, max_cs, Config::default());

    let led = Output::new(p.PIN_13, Level::Low);

    display::display_init(&spawner, eve_device, eve_pd).await;
    keyboard::keyboard_init(&spawner, max_device).await;
    modes::modes_init(spawner);
    host::host_init(spawner, p.CORE1, pio0, p.PIN_0, p.PIN_1, p.PIN_2, p.PIN_3);
    
    spawner.spawn(blink_task(led)).unwrap();
}
