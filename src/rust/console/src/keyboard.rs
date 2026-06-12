// USB host driver ported from jakakordez/max3421e-stm32 (MAX3421E.c)

use embassy_embedded_hal::shared_bus::asynch::spi::SpiDeviceWithConfig;
use embassy_executor::Spawner;
use embassy_rp::gpio::{Input, Output};
use embassy_rp::peripherals::SPI1;
use embassy_rp::spi::{Async, Spi};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::Channel;
use embassy_time::Timer;
use embedded_hal_async::spi::{Operation, SpiDevice};

use crate::keymap::*;
use crate::max3421e::*;

type MaxSpiDevice = SpiDeviceWithConfig<
    'static,
    CriticalSectionRawMutex,
    Spi<'static, SPI1, Async>,
    Output<'static>,
>;

static KEYBOARD_CHANNEL: Channel<CriticalSectionRawMutex, u8, 64> = Channel::new();

struct HidEndpoint {
    addr: u8,
    max_packet: u8,
}

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

pub async fn keyboard_init(spawner: &Spawner, mut device: MaxSpiDevice, irq: Input<'static>) {
    max_init(&mut device).await;
    spawner.spawn(keyboard_task(device, irq)).unwrap();
}

#[embassy_executor::task]
async fn keyboard_task(mut device: MaxSpiDevice, mut _irq: Input<'static>) {
    loop {
        // wait for device connection
        wait_for_connect(&mut device).await;
        Timer::after_millis(500).await;

        let ep = match enumerate(&mut device).await {
            Some(ep) => ep,
            None => {
                log::error!("keyboard_task: enumeration failed, retrying");
                continue;
            }
        };
        log::info!(
            "keyboard_task: ep addr=0x{:02X} max_packet={}",
            ep.addr,
            ep.max_packet
        );

        poll_hid(&mut device, &ep).await;
    }
}

// poll the bus until a device is present, then clear the connect IRQ
// samples current J/K state rather than waiting for a CONNIRQ edge, so a device
// already attached at startup (whose edge we missed) is still detected
async fn wait_for_connect(device: &mut MaxSpiDevice) {
    loop {
        reg_write(device, HCTL, bmBUSSAMPLE).await;
        let hrsl = reg_read(device, HRSL).await;
        if hrsl & (bmJSTATUS | bmKSTATUS) != 0 {
            reg_write(device, HIRQ, bmCONNIRQ).await;
            return;
        }
        Timer::after_millis(10).await;
    }
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
    device
        .transaction(&mut [Operation::Write(&[reg | 0x02]), Operation::Write(data)])
        .await
        .unwrap();
}

// read N bytes from a FIFO register in one SPI transaction
async fn read_fifo(device: &mut MaxSpiDevice, reg: u8, data: &mut [u8]) {
    device
        .transaction(&mut [Operation::Write(&[reg]), Operation::Read(data)])
        .await
        .unwrap();
}

// --- bus helpers ---

// wait on a specified IRQ, then clear it
async fn wait_and_clear_irq(device: &mut MaxSpiDevice, reg: u8, value: u8) {
    while (reg_read(device, reg).await) & value == 0 {
        Timer::after_micros(500).await
    }

    reg_write(device, reg, value).await;
}

// wait for N SOF frame IRQs
async fn wait_frames(device: &mut MaxSpiDevice, n: u8) {
    reg_write(device, HIRQ, bmFRAMEIRQ).await;
    for _ in 0..n {
        wait_and_clear_irq(device, HIRQ, bmFRAMEIRQ).await;
    }
}

// reset the bus
async fn reset_bus(device: &mut MaxSpiDevice) {
    reg_write(device, HCTL, bmBUSRST).await;
    while (reg_read(device, HCTL).await) & bmBUSRST != 0 {
        Timer::after_millis(1).await;
    }

    reg_write(device, HCTL, bmBUSSAMPLE).await;
    wait_frames(device, 200).await;
}

// write HXFR, spin on HXFRDNIRQ, clear it, return HRSL result nibble
// retries on NAK up to NAK_LIMIT and on TIMEOUT up to RETRY_LIMIT
async fn dispatch_pkt(device: &mut MaxSpiDevice, token: u8, ep: u8) -> u8 {
    let mut retry_count = 0;
    let mut nak_count = 0;

    loop {
        reg_write(device, HXFR, token | ep).await;
        wait_and_clear_irq(device, HIRQ, bmHXFRDNIRQ).await;
        let result = (reg_read(device, HRSL).await) & bmHRSLT;

        if result == hrNAK {
            nak_count += 1;
            if nak_count == NAK_LIMIT {
                return result;
            }

            wait_frames(device, 1).await;
            continue;
        }

        if result == hrTIMEOUT {
            retry_count += 1;
            if retry_count == RETRY_LIMIT {
                return result;
            }
            continue;
        }

        return result;
    }
}

// dispatch tokIN on ep, drain RCVFIFO into buf, repeat until short packet or buf full
// returns 0 on success, hrXxx on error
async fn in_transfer(device: &mut MaxSpiDevice, ep: u8, max_packet: u8, buf: &mut [u8]) -> u8 {
    let mut result;
    let mut xfrlen = 0;

    loop {
        result = dispatch_pkt(device, tokIN, ep).await;
        if result != 0 {
            return result;
        }

        let pkt_size = reg_read(device, RCVBC).await as usize;
        if xfrlen + pkt_size > buf.len() {
            log::error!(
                "in_transfer: overflow xfrlen={} pkt_size={} buf={}",
                xfrlen,
                pkt_size,
                buf.len()
            );
            return hrBADBC;
        }
        read_fifo(device, RCVFIFO, &mut buf[xfrlen..xfrlen + pkt_size]).await;

        reg_write(device, HIRQ, bmRCVDAVIRQ).await;
        xfrlen += pkt_size;

        if pkt_size < max_packet as usize {
            return result;
        }

        if xfrlen >= buf.len() {
            return result;
        }
    }
}

// --- control transfers ---

// control read: SETUP + one or more IN packets into buf + OUTHS status
// returns 0 on success, hrXxx on error
async fn ctrl_in(
    device: &mut MaxSpiDevice,
    setup_pkt: &[u8; 8],
    max_packet: u8,
    buf: &mut [u8],
) -> u8 {
    let mut result;

    write_fifo(device, SUDFIFO, setup_pkt).await;
    result = dispatch_pkt(device, tokSETUP, 0).await;
    if result != 0 {
        return result;
    }

    reg_write(device, HCTL, bmRCVTOG1).await;
    result = in_transfer(device, 0, max_packet, buf).await;
    if result != 0 {
        return result;
    }

    0
}

// control write with no data stage: SETUP + INHS status
async fn ctrl_nodata(device: &mut MaxSpiDevice, setup_pkt: &[u8; 8]) -> u8 {
    write_fifo(device, SUDFIFO, setup_pkt).await;
    let result = dispatch_pkt(device, tokSETUP, 0).await;
    if result != 0 {
        return result;
    }

    dispatch_pkt(device, tokINHS, 0).await
}

// --- enumeration ---
// USB enumeration: bring a freshly connected device online and find its HID endpoint.
//
// All devices power up listening on address 0 -- the USB "parking spot" for unconfigured
// devices. Only one device may sit at address 0 at a time, so enumeration is sequential.
//
// Steps:
//   1. bus reset -- puts the device in the known initial state
//   2. GET_DESCRIPTOR(Device, 8) -- fetch just enough to learn bMaxPacketSize0 (byte 7)
//   3. bus reset -- required before SET_ADDRESS per the USB spec
//   4. SET_ADDRESS(1) -- move the device off address 0; all further traffic goes to address 1
//   5. GET_DESCRIPTOR(Config) -- read wTotalLength, then fetch the full descriptor blob
//   6. SET_CONFIGURATION(1) -- activate the configuration so endpoints become live
//   7. SET_PROTOCOL(0) -- switch HID device to boot protocol (fixed 8-byte reports)
//
// returns the HID interrupt-IN endpoint, or None if any step fails
async fn enumerate(device: &mut MaxSpiDevice) -> Option<HidEndpoint> {
    // GET_DESCRIPTOR(Device, 8) -- first 8 bytes are enough to read bMaxPacketSize0 (byte 7)
    let get_dev_desc: [u8; 8] = [0x80, 0x06, 0x00, 0x01, 0x00, 0x00, 0x08, 0x00];
    // SET_ADDRESS(1)
    let set_addr: [u8; 8] = [0x00, 0x05, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00];
    // GET_DESCRIPTOR(Config) -- fill wLength at [6] before use
    let mut get_cfg_desc: [u8; 8] = [0x80, 0x06, 0x00, 0x02, 0x00, 0x00, 0x04, 0x00];
    // SET_CONFIGURATION(1)
    let set_cfg: [u8; 8] = [0x00, 0x09, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00];
    // SET_PROTOCOL(0) -- boot protocol, interface 0
    let set_proto: [u8; 8] = [0x21, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];

    // park the bus
    reset_bus(device).await;

    // grab a truncated device description, to pull the max packet size of it
    reg_write(device, PERADDR, 0).await;
    let mut packet_size_buf: [u8; 8] = [0u8; 8];
    let r = ctrl_in(device, &get_dev_desc, 8, packet_size_buf.as_mut_slice()).await;
    if r != 0 {
        log::error!("enumerate: GET_DESCRIPTOR(Device) failed: 0x{:02X}", r);
        return None;
    }
    let max_packet = packet_size_buf[7];

    // park the bus again
    reset_bus(device).await;

    // move the device to address 1
    let r = ctrl_nodata(device, &set_addr).await;
    if r != 0 {
        log::error!("enumerate: SET_ADDRESS failed: 0x{:02X}", r);
        return None;
    }
    wait_frames(device, 30).await;
    reg_write(device, PERADDR, 1).await;

    // grab the device config size
    let mut config_size_buf: [u8; 4] = [0u8; 4];
    let r = ctrl_in(
        device,
        &get_cfg_desc,
        max_packet,
        config_size_buf.as_mut_slice(),
    )
    .await;
    if r != 0 {
        log::error!("enumerate: GET_DESCRIPTOR(Config, 4) failed: 0x{:02X}", r);
        return None;
    }
    let max_config = config_size_buf[2] as usize + 256 * config_size_buf[3] as usize;

    // grab the full device config
    get_cfg_desc[6] = config_size_buf[2];
    get_cfg_desc[7] = config_size_buf[3];
    let mut config_buf = [0u8; 256];
    let r = ctrl_in(
        device,
        &get_cfg_desc,
        max_packet,
        &mut config_buf[..max_config],
    )
    .await;
    if r != 0 {
        log::error!(
            "enumerate: GET_DESCRIPTOR(Config, full) failed: 0x{:02X}",
            r
        );
        return None;
    }
    // activate the configuration so the endpoints come live
    let r = ctrl_nodata(device, &set_cfg).await;
    if r != 0 {
        log::error!("enumerate: SET_CONFIGURATION failed: 0x{:02X}", r);
        return None;
    }

    // switch to boot protocol (fixed 8-byte reports)
    let r = ctrl_nodata(device, &set_proto).await;
    if r != 0 {
        log::error!("enumerate: SET_PROTOCOL failed: 0x{:02X}", r);
        return None;
    }

    // grab the info needed to setup the boot protocol
    find_hid_ep(&config_buf[..max_config])
}

// parse config descriptor blob for first interrupt IN endpoint
fn find_hid_ep(data: &[u8]) -> Option<HidEndpoint> {
    let mut i = 0;
    while i + 2 <= data.len() {
        let len = data[i] as usize;
        let typ = data[i + 1];

        if len == 0 {
            break;
        }

        if i + len > data.len() {
            break;
        }

        // endpoint descriptor (type 0x05), at least 6 bytes
        if typ == 0x05 && len >= 6 {
            let addr = data[i + 2];
            let attrs = data[i + 3];
            let max_packet = data[i + 4];

            // interrupt IN: bmAttributes == 0x03, direction bit set
            if attrs == 0x03 && addr & 0x80 != 0 {
                return Some(HidEndpoint { addr, max_packet });
            }
        }

        i += len;
    }
    None
}

// --- HID polling ---

// tokIN polling loop on hid_ep; pushes decoded bytes to KEYBOARD_CHANNEL
async fn poll_hid(device: &mut MaxSpiDevice, ep: &HidEndpoint) {
    // clear the stale connect IRQ left over from enumeration's bus resets,
    // so the loop below only fires on an actual disconnect
    reg_write(device, HIRQ, bmCONNIRQ).await;

    let mut report = [0u8; 8];
    loop {
        // bail on disconnect so keyboard_task loops back to wait_for_connect
        if reg_read(device, HIRQ).await & bmCONNIRQ != 0 {
            reg_write(device, HIRQ, bmCONNIRQ).await;
            return;
        }

        let r = in_transfer(device, ep.addr & 0x0F, ep.max_packet, &mut report).await;
        if r == 0 && report.iter().any(|&b| b != 0) {
            log::info!("poll_hid: report={:02X?}", report);
        }
        // TODO: diff against previous report, decode, push to KEYBOARD_CHANNEL
        Timer::after_millis(100).await;
    }
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
    // configure SPI: full duplex, active-high INT, GPXB pin select
    reg_write(device, PINCTL, bmFDUPSPI | bmINTLEVEL | bmGPXB).await;

    // chip reset
    reg_write(device, USBCTL, bmCHIPRES).await;
    reg_write(device, USBCTL, 0x00).await;

    // wait for oscillator
    while reg_read(device, USBIRQ).await & bmOSCOKIRQ == 0 {
        Timer::after_millis(1).await;
    }

    // host mode: low speed, separate IRQs, SOF keep-alive
    reg_write(device, MODE, MODE_LS_HOST | bmSEPIRQ).await;

    // enable connection detect and frame interrupts
    reg_write(device, HIEN, bmCONDETIE | bmFRAMEIE).await;

    // sample bus state and clear connection IRQ
    reg_write(device, HCTL, bmBUSSAMPLE).await;
    reg_write(device, HIRQ, bmCONDETIRQ).await;

    // enable CPU interrupt output
    reg_write(device, CPUCTL, bmIE).await;
}
