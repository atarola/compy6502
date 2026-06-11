use embassy_embedded_hal::shared_bus::asynch::spi::SpiDeviceWithConfig;
use embassy_executor::Spawner;
use embassy_rp::gpio::{Input, Output};
use embassy_rp::peripherals::SPI1;
use embassy_rp::spi::{Async, Spi};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::Channel;
use embassy_time::Timer;
use embedded_hal_async::spi::{Operation, SpiDevice};

use crate::max3421e::*;

type MaxSpiDevice = SpiDeviceWithConfig<
    'static,
    CriticalSectionRawMutex,
    Spi<'static, SPI1, Async>,
    Output<'static>,
>;

static KEYBOARD_CHANNEL: Channel<CriticalSectionRawMutex, u8, 64> = Channel::new();

pub struct KeyboardHandle;

impl KeyboardHandle {
    pub fn new() -> KeyboardHandle {
        KeyboardHandle
    }

    pub fn has_data(&self) -> bool {
        KEYBOARD_CHANNEL.len() > 0
    }

    pub async fn get_char(&self) -> Option<u8> {
        KEYBOARD_CHANNEL.try_receive().ok()
    }
}

pub fn keyboard_init(spawner: &Spawner, device: MaxSpiDevice, irq: Input<'static>) {
    spawner.spawn(keyboard_task(device, irq)).unwrap();
}

#[embassy_executor::task]
async fn keyboard_task(mut device: MaxSpiDevice, mut _irq: Input<'static>) {
    log::info!("keyboard_task: start");
    max_init(&mut device).await;

    // wait for device connection
    log::info!("keyboard_task: waiting for device");
    loop {
        let hirq = reg_read(&mut device, HIRQ).await;
        if hirq & bmCONNIRQ != 0 {
            reg_write(&mut device, HIRQ, bmCONNIRQ).await;
            break;
        }
        Timer::after_millis(10).await;
    }
    log::info!("keyboard_task: device connected");

    wait_frames(&mut device, 200).await;

    let (hid_ep, _max_pkt) = enumerate(&mut device).await;
    log::info!("keyboard_task: enumerated, ep=0x{:02X}", hid_ep);

    poll_hid(&mut device, hid_ep).await;
}

// --- SPI primitives ---

async fn reg_read(device: &mut MaxSpiDevice, reg: u8) -> u8 {
    let mut rx = [0u8; 1];
    device
        .transaction(&mut [Operation::Write(&[reg]), Operation::Read(&mut rx)])
        .await
        .unwrap();
    rx[0]
}

async fn reg_write(device: &mut MaxSpiDevice, reg: u8, val: u8) {
    device
        .transaction(&mut [Operation::Write(&[reg | 0x02, val])])
        .await
        .unwrap();
}

// write N bytes into a FIFO register in one SPI transaction
async fn write_fifo(device: &mut MaxSpiDevice, reg: u8, data: &[u8]) {
    todo!()
}

// --- bus helpers ---

// wait for N SOF frame IRQs
async fn wait_frames(device: &mut MaxSpiDevice, n: u8) {
    todo!()
}

// write HXFR, spin on HXFRDNIRQ, clear it, return HRSL result nibble
// retries on NAK up to NAK_LIMIT and on TIMEOUT up to RETRY_LIMIT
async fn dispatch_pkt(device: &mut MaxSpiDevice, token: u8, ep: u8) -> u8 {
    todo!()
}

// --- control transfers ---

// control read: SETUP + one or more IN packets into buf + OUTHS status
// returns number of bytes read
async fn ctrl_in(device: &mut MaxSpiDevice, setup_pkt: &[u8; 8], buf: &mut [u8]) -> usize {
    todo!()
}

// control write with no data stage: SETUP + INHS status
async fn ctrl_nodata(device: &mut MaxSpiDevice, setup_pkt: &[u8; 8]) {
    todo!()
}

// --- enumeration ---

// full USB enumeration sequence:
//   bus reset -> GET_DESCRIPTOR(Device) -> bus reset -> SET_ADDRESS(1)
//   -> GET_DESCRIPTOR(Config) -> SET_CONFIGURATION(1) -> SET_PROTOCOL(0)
// returns (hid_ep_addr, ep_max_packet)
async fn enumerate(device: &mut MaxSpiDevice) -> (u8, u8) {
    todo!()
}

// parse config descriptor blob for first interrupt IN endpoint
// returns (ep_addr, max_packet_size)
fn find_hid_ep(data: &[u8]) -> Option<(u8, u8)> {
    todo!()
}

// --- HID polling ---

// tokIN polling loop on hid_ep; pushes decoded bytes to KEYBOARD_CHANNEL
async fn poll_hid(device: &mut MaxSpiDevice, ep: u8) {
    todo!()
}

// diff current and previous 8-byte HID boot report; push new keypresses to channel
fn process_report(report: &[u8; 8], prev: &[u8; 8]) {
    todo!()
}

// HID boot protocol keycode -> ASCII; returns None for non-printable / unhandled
fn keycode_to_ascii(keycode: u8, shifted: bool) -> Option<u8> {
    todo!()
}

// push ESC + seq bytes to KEYBOARD_CHANNEL (for arrow keys, F-keys, etc.)
fn send_ansi(seq: &[u8]) {
    todo!()
}

// --- init ---

async fn max_init(device: &mut MaxSpiDevice) {
    log::info!("max_init: start");

    reg_write(device, PINCTL, bmFDUPSPI | bmINTLEVEL | bmGPXB).await;
    log::info!("max_init: PINCTL set");

    reg_write(device, USBCTL, bmCHIPRES).await;
    reg_write(device, USBCTL, 0x00).await;
    log::info!("max_init: waiting for oscillator");
    while reg_read(device, USBIRQ).await & bmOSCOKIRQ == 0 {
        Timer::after_millis(1).await;
    }
    log::info!("max_init: oscillator ok");

    reg_write(device, MODE, bmDPPULLDN | bmDMPULLDN | bmHOST | bmSEPIRQ | bmSOFKAENAB).await;
    log::info!("max_init: MODE set");

    reg_write(device, HIEN, bmCONDETIE | bmFRAMEIE).await;
    log::info!("max_init: HIEN set");

    reg_write(device, HCTL, bmBUSSAMPLE).await;
    Timer::after_millis(1).await;
    let hirq = reg_read(device, HIRQ).await;
    log::info!("max_init: HIRQ after busprobe = 0x{:02X}", hirq);
    reg_write(device, HIRQ, bmCONDETIRQ).await;

    reg_write(device, CPUCTL, bmIE).await;
    log::info!("max_init: done");
}
