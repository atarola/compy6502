use embassy_embedded_hal::shared_bus::asynch::spi::SpiDeviceWithConfig;
use embassy_executor::Spawner;
use embassy_rp::gpio::Output;
use embassy_rp::peripherals::SPI1;
use embassy_rp::spi::{Async, Spi};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::Channel;
use embassy_time::Timer;
use embedded_hal_async::spi::{Operation, SpiDevice};
use heapless::Vec;

use DisplayCmd::{BeginBulk, BulkByte, Cmd, EndBulk, Write8, Write16, Write32};

use crate::eve::*;

type EveSpiDevice = SpiDeviceWithConfig<
    'static,
    CriticalSectionRawMutex,
    Spi<'static, SPI1, Async>,
    Output<'static>,
>;

static DISPLAY_CHANNEL: Channel<CriticalSectionRawMutex, DisplayCmd, 4096> = Channel::new();

pub enum DisplayCmd {
    BeginBulk(u32),
    BulkByte(u8),
    EndBulk,
    Cmd(u8),
    Write8(u32, u8),
    Write16(u32, u16),
    Write32(u32, u32),
}

pub struct DisplayHandle;

impl DisplayHandle {
    pub fn new() -> DisplayHandle {
        DisplayHandle
    }

    pub async fn cmd(&self, cmd: u8) {
        DISPLAY_CHANNEL.send(Cmd(cmd)).await;
    }

    pub async fn write8(&self, addr: u32, data: u8) {
        DISPLAY_CHANNEL.send(Write8(addr, data)).await;
    }

    pub async fn write16(&self, addr: u32, data: u16) {
        DISPLAY_CHANNEL.send(Write16(addr, data)).await;
    }

    pub async fn write32(&self, addr: u32, data: u32) {
        DISPLAY_CHANNEL.send(Write32(addr, data)).await;
    }

    pub async fn begin_bulk(&self, addr: u32) {
        DISPLAY_CHANNEL.send(BeginBulk(addr)).await;
    }

    pub async fn bulk_byte(&self, b: u8) {
        DISPLAY_CHANNEL.send(BulkByte(b)).await;
    }

    pub async fn end_bulk(&self) {
        DISPLAY_CHANNEL.send(EndBulk).await;
    }
}

pub async fn display_init(
    spawner: &Spawner,
    mut device: EveSpiDevice,
    mut pd: Output<'static>,
) -> DisplayHandle {
    eve_init(&mut device, &mut pd).await;
    spawner.spawn(display_task(device)).unwrap();
    DisplayHandle::new()
}

fn handle_begin_bulk(addr: u32, bulk_addr: &mut Option<u32>, bulk_buf: &mut Vec<u8, 4096>) {
    *bulk_addr = Some(addr);
    bulk_buf.clear();
}

fn handle_bulk_byte(b: u8, bulk_buf: &mut Vec<u8, 4096>) {
    let _ = bulk_buf.push(b);
}

async fn handle_end_bulk(
    device: &mut EveSpiDevice,
    bulk_addr: &mut Option<u32>,
    bulk_buf: &mut Vec<u8, 4096>,
) {
    if let Some(addr) = bulk_addr.take() {
        exec_bulk(device, addr, bulk_buf).await;
        bulk_buf.clear();
    }
}

async fn exec_bulk(device: &mut EveSpiDevice, addr: u32, data: &[u8]) {
    let mut hdr = [0u8; 3];
    encode_addr(&mut hdr, addr, true);
    device
        .transaction(&mut [Operation::Write(&hdr), Operation::Write(data)])
        .await
        .unwrap();
}

async fn exec_cmd(device: &mut EveSpiDevice, cmd: u8) {
    let tx = [cmd, 0x00, 0x00];
    device
        .transaction(&mut [Operation::Write(&tx)])
        .await
        .unwrap();
}

async fn exec_write8(device: &mut EveSpiDevice, addr: u32, data: u8) {
    let mut tx = [0u8; 4];
    encode_addr(&mut tx, addr, true);
    encode_data(&mut tx[3..], data as u32, 1);
    device
        .transaction(&mut [Operation::Write(&tx)])
        .await
        .unwrap();
}

async fn exec_write16(device: &mut EveSpiDevice, addr: u32, data: u16) {
    let mut tx = [0u8; 5];
    encode_addr(&mut tx, addr, true);
    encode_data(&mut tx[3..], data as u32, 2);
    device
        .transaction(&mut [Operation::Write(&tx)])
        .await
        .unwrap();
}

async fn exec_write32(device: &mut EveSpiDevice, addr: u32, data: u32) {
    let mut tx = [0u8; 7];
    encode_addr(&mut tx, addr, true);
    encode_data(&mut tx[3..], data, 4);
    device
        .transaction(&mut [Operation::Write(&tx)])
        .await
        .unwrap();
}

async fn exec_read8(device: &mut EveSpiDevice, addr: u32) -> u8 {
    let mut tx = [0u8; 4];
    let mut rx = [0u8; 1];
    encode_addr(&mut tx, addr, false);
    device
        .transaction(&mut [Operation::Write(&tx), Operation::Read(&mut rx)])
        .await
        .unwrap();
    rx[0]
}

fn encode_addr(buf: &mut [u8], addr: u32, write: bool) {
    buf[0] = ((addr >> 16) & 0x3F | if write { 0x80 } else { 0x00 }) as u8;
    buf[1] = ((addr >> 8) & 0xFF) as u8;
    buf[2] = ((addr >> 0) & 0xFF) as u8;
}

fn encode_data(buf: &mut [u8], data: u32, len: usize) {
    for i in 0..len {
        buf[i] = ((data >> (i * 8)) & 0xFF) as u8;
    }
}

async fn eve_init(device: &mut EveSpiDevice, pd: &mut Output<'static>) {
    // power cycle the screen
    pd.set_low();
    Timer::after_millis(6).await;
    pd.set_high();
    Timer::after_millis(21).await;

    // set the clock and boot up eve chip
    exec_cmd(device, EVE_CLKEXT).await;
    exec_cmd(device, EVE_ACTIVE).await;
    Timer::after_millis(21).await;

    // wait till the chip starts to respond
    while exec_read8(device, REG_ID).await != 0x7C {
        Timer::after_millis(1).await;
    }

    // wait for reset completion
    while exec_read8(device, REG_CPURESET).await & 0x03 != 0x00 {
        Timer::after_millis(1).await;
    }

    // backlight off
    exec_write8(device, REG_PWM_DUTY, 0).await;

    // display timing
    exec_write16(device, REG_HSIZE, EVE_HSIZE).await;
    exec_write16(device, REG_HCYCLE, EVE_HCYCLE).await;
    exec_write16(device, REG_HOFFSET, EVE_HOFFSET).await;
    exec_write16(device, REG_HSYNC0, EVE_HSYNC0).await;
    exec_write16(device, REG_HSYNC1, EVE_HSYNC1).await;
    exec_write16(device, REG_VSIZE, EVE_VSIZE).await;
    exec_write16(device, REG_VCYCLE, EVE_VCYCLE).await;
    exec_write16(device, REG_VOFFSET, EVE_VOFFSET).await;
    exec_write16(device, REG_VSYNC0, EVE_VSYNC0).await;
    exec_write16(device, REG_VSYNC1, EVE_VSYNC1).await;
    exec_write8(device, REG_SWIZZLE, EVE_SWIZZLE).await;
    exec_write8(device, REG_PCLK_POL, EVE_PCLKPOL).await;
    exec_write8(device, REG_CSPREAD, EVE_CSPREAD).await;

    // touch
    exec_write8(device, REG_TOUCH_MODE, EVE_TMODE_CONTINUOUS).await;
    exec_write16(device, REG_TOUCH_RZTHRESH, EVE_TOUCH_RZTHRESH).await;

    // audio off
    exec_write8(device, REG_VOL_PB, 0x00).await;
    exec_write8(device, REG_VOL_SOUND, 0x00).await;
    exec_write16(device, REG_SOUND, 0x6000).await;

    // basic display list
    exec_write32(device, EVE_RAM_DL, DL_CLEAR_RGB).await;
    exec_write32(device, EVE_RAM_DL + 4, clear(1, 1, 1)).await;
    exec_write32(device, EVE_RAM_DL + 8, DL_DISPLAY).await;
    exec_write8(device, REG_DLSWAP, EVE_DLSWAP_FRAME).await;

    // enable display and pixel clock
    exec_write8(device, REG_GPIO, 0x80).await;
    exec_write8(device, REG_PCLK, EVE_PCLK).await;

    // backlight on at 25%
    exec_write8(device, REG_PWM_DUTY, 0x50).await;

    // wait for coprocessor
    while exec_read8(device, REG_CPURESET).await != 0x00 {
        Timer::after_millis(1).await;
    }
}

#[embassy_executor::task]
async fn display_task(mut device: EveSpiDevice) {
    let receiver = DISPLAY_CHANNEL.receiver();
    let mut bulk_addr: Option<u32> = None;
    let mut bulk_buf: Vec<u8, 4096> = Vec::new();

    loop {
        match receiver.receive().await {
            DisplayCmd::BeginBulk(addr) => handle_begin_bulk(addr, &mut bulk_addr, &mut bulk_buf),
            DisplayCmd::BulkByte(b) => handle_bulk_byte(b, &mut bulk_buf),
            DisplayCmd::EndBulk => {
                handle_end_bulk(&mut device, &mut bulk_addr, &mut bulk_buf).await
            }
            DisplayCmd::Cmd(cmd) => exec_cmd(&mut device, cmd).await,
            DisplayCmd::Write8(addr, data) => exec_write8(&mut device, addr, data).await,
            DisplayCmd::Write16(addr, data) => exec_write16(&mut device, addr, data).await,
            DisplayCmd::Write32(addr, data) => exec_write32(&mut device, addr, data).await,
        }
    }
}
