#![allow(dead_code)]
#![allow(non_upper_case_globals)]

// Register addresses (read command byte = register_number << 3)
// Write command byte = reg | 0x02
pub const RCVFIFO: u8 = 0x08; // R1
pub const SNDFIFO: u8 = 0x10; // R2
pub const SUDFIFO: u8 = 0x20; // R4
pub const RCVBC: u8 = 0x30; // R6
pub const SNDBC: u8 = 0x38; // R7
pub const USBIRQ: u8 = 0x68; // R13
pub const USBIEN: u8 = 0x70; // R14
pub const USBCTL: u8 = 0x78; // R15
pub const CPUCTL: u8 = 0x80; // R16
pub const PINCTL: u8 = 0x88; // R17
pub const REVISION: u8 = 0x90; // R18
pub const IOPINS1: u8 = 0xA0; // R20
pub const IOPINS2: u8 = 0xA8; // R21
pub const GPINIRQ: u8 = 0xB0; // R22
pub const GPINIEN: u8 = 0xB8; // R23
pub const GPINPOL: u8 = 0xC0; // R24
pub const HIRQ: u8 = 0xC8; // R25
pub const HIEN: u8 = 0xD0; // R26
pub const MODE: u8 = 0xD8; // R27
pub const PERADDR: u8 = 0xE0; // R28
pub const HCTL: u8 = 0xE8; // R29
pub const HXFR: u8 = 0xF0; // R30
pub const HRSL: u8 = 0xF8; // R31

// USBIRQ / USBIEN bits (host mode -- only these bits are active)
pub const bmOSCOKIRQ: u8 = 0x01; // b0
pub const bmNOVBUSIRQ: u8 = 0x20; // b5
pub const bmVBUSIRQ: u8 = 0x40; // b6

pub const bmOSCOKIE: u8 = bmOSCOKIRQ;
pub const bmNOVBUSIE: u8 = bmNOVBUSIRQ;
pub const bmVBUSIE: u8 = bmVBUSIRQ;

// USBCTL bits (host mode)
pub const bmCHIPRES: u8 = 0x20; // b5
pub const bmPWRDOWN: u8 = 0x10; // b4

// CPUCTL bits
pub const bmIE: u8 = 0x01; // b0
pub const bmPULSEWID0: u8 = 0x40; // b6
pub const bmPULSEWID1: u8 = 0x80; // b7

// PINCTL bits
pub const bmGPXA: u8 = 0x01; // b0
pub const bmGPXB: u8 = 0x02; // b1
pub const bmPOSINT: u8 = 0x04; // b2
pub const bmINTLEVEL: u8 = 0x08; // b3
pub const bmFDUPSPI: u8 = 0x10; // b4
pub const bmEP0INAK: u8 = 0x20; // b5
pub const bmEP2INAK: u8 = 0x40; // b6
pub const bmEP3INAK: u8 = 0x80; // b7

// HIRQ / HIEN bits
pub const bmBUSEVENTIRQ: u8 = 0x01; // b0
pub const bmRSMREQIRQ: u8 = 0x02; // b1
pub const bmRCVDAVIRQ: u8 = 0x04; // b2
pub const bmSNDBAVIRQ: u8 = 0x08; // b3
pub const bmSUSDNIRQ: u8 = 0x10; // b4
pub const bmCONNIRQ: u8 = 0x20; // b5
pub const bmFRAMEIRQ: u8 = 0x40; // b6
pub const bmHXFRDNIRQ: u8 = 0x80; // b7

pub const bmBUSEVENTIE: u8 = bmBUSEVENTIRQ;
pub const bmRSMREQIE: u8 = bmRSMREQIRQ;
pub const bmRCVDAVIE: u8 = bmRCVDAVIRQ;
pub const bmSNDBAVIE: u8 = bmSNDBAVIRQ;
pub const bmSUSDNIE: u8 = bmSUSDNIRQ;
pub const bmCONNIE: u8 = bmCONNIRQ;
pub const bmFRAMEIE: u8 = bmFRAMEIRQ;
pub const bmHXFRDNIE: u8 = bmHXFRDNIRQ;

// notes.md uses bmCONDETIRQ/bmCONDETIE -- aliases to CONNIRQ/CONNIE
pub const bmCONDETIRQ: u8 = bmCONNIRQ;
pub const bmCONDETIE: u8 = bmCONNIE;

// MODE bits
pub const bmHOST: u8 = 0x01; // b0
pub const bmSPEED: u8 = 0x02; // b1
pub const bmHUBPRE: u8 = 0x04; // b2
pub const bmSOFKAENAB: u8 = 0x08; // b3
pub const bmSEPIRQ: u8 = 0x10; // b4
pub const bmDELAYISO: u8 = 0x20; // b5
pub const bmDMPULLDN: u8 = 0x40; // b6
pub const bmDPPULLDN: u8 = 0x80; // b7

pub const MODE_FS_HOST: u8 = bmDPPULLDN | bmDMPULLDN | bmHOST | bmSOFKAENAB;
pub const MODE_LS_HOST: u8 = bmDPPULLDN | bmDMPULLDN | bmHOST | bmSPEED | bmSOFKAENAB;

// HCTL bits
pub const bmBUSRST: u8 = 0x01; // b0
pub const bmFRMRST: u8 = 0x02; // b1
pub const bmBUSSAMPLE: u8 = 0x04; // b2
pub const bmSIGRSM: u8 = 0x08; // b3
pub const bmRCVTOG0: u8 = 0x10; // b4
pub const bmRCVTOG1: u8 = 0x20; // b5
pub const bmSNDTOG0: u8 = 0x40; // b6
pub const bmSNDTOG1: u8 = 0x80; // b7

// HXFR token bits
pub const bmEP_MASK: u8 = 0x0F; // b3:b0 -- endpoint number
pub const bmSETUP: u8 = 0x10; // b4
pub const bmOUTNIN: u8 = 0x20; // b5
pub const bmISO: u8 = 0x40; // b6
pub const bmHS: u8 = 0x80; // b7

pub const tokIN: u8 = 0x00;
pub const tokSETUP: u8 = 0x10;
pub const tokOUT: u8 = 0x20;
pub const tokINHS: u8 = 0x80;
pub const tokOUTHS: u8 = 0xA0;
pub const tokISOIN: u8 = 0x40;
pub const tokISOOUT: u8 = 0x60;

// HRSL bits
pub const bmHRSLT: u8 = 0x0F; // b3:b0 -- result code
pub const bmRCVTOGRD: u8 = 0x10; // b4
pub const bmSNDTOGRD: u8 = 0x20; // b5
pub const bmKSTATUS: u8 = 0x40; // b6
pub const bmJSTATUS: u8 = 0x80; // b7

// HRSL result codes (lower nibble)
pub const hrSUCCESS: u8 = 0x00;
pub const hrBUSY: u8 = 0x01;
pub const hrBADREQ: u8 = 0x02;
pub const hrUNDEF: u8 = 0x03;
pub const hrNAK: u8 = 0x04;
pub const hrSTALL: u8 = 0x05;
pub const hrTOGERR: u8 = 0x06;
pub const hrWRONGPID: u8 = 0x07;
pub const hrBADBC: u8 = 0x08;
pub const hrPIDERR: u8 = 0x09;
pub const hrPKTERR: u8 = 0x0A;
pub const hrCRCERR: u8 = 0x0B;
pub const hrKERR: u8 = 0x0C;
pub const hrJERR: u8 = 0x0D;
pub const hrTIMEOUT: u8 = 0x0E;
pub const hrBABBLE: u8 = 0x0F;

pub const NAK_LIMIT: u8 = 200;
pub const NAK_LIMIT_HID: u8 = 3;
pub const RETRY_LIMIT: u8 = 3;
