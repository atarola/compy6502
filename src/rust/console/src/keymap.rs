// HID boot protocol modifier byte (report byte 0) bit masks
pub const MOD_LEFT_CTRL: u8 = 0x01;
pub const MOD_LEFT_SHIFT: u8 = 0x02;
pub const MOD_LEFT_ALT: u8 = 0x04;
pub const MOD_LEFT_GUI: u8 = 0x08;
pub const MOD_RIGHT_CTRL: u8 = 0x10;
pub const MOD_RIGHT_SHIFT: u8 = 0x20;
pub const MOD_RIGHT_ALT: u8 = 0x40;
pub const MOD_RIGHT_GUI: u8 = 0x80;

// HID keycode lookup tables.
// ASCII table is HID_KEYCODE_TO_ASCII from TinyUSB:
//   https://github.com/hathach/tinyusb/blob/master/src/class/hid/hid.h
// ANSI table is ported from src/arduino/console/keyboard.cpp (ansiKeys).

// HID boot keycode -> ANSI escape sequence, ported from the arduino console ansiKeys table
// covers the non-ASCII keys we care about: arrows, home/end, delete, F1-F4
pub static KEYCODE_TO_ANSI: phf::Map<u8, &[u8]> = phf::phf_map! {
    0x52u8 => b"\x1b[A",  // Arrow Up
    0x51u8 => b"\x1b[B",  // Arrow Down
    0x4fu8 => b"\x1b[C",  // Arrow Right
    0x50u8 => b"\x1b[D",  // Arrow Left
    0x4au8 => b"\x1b[H",  // Home
    0x4du8 => b"\x1b[F",  // End
    0x4cu8 => b"\x1b[3~", // Delete
    0x3au8 => b"\x1bOP",  // F1
    0x3bu8 => b"\x1bOQ",  // F2
    0x3cu8 => b"\x1bOR",  // F3
    0x3du8 => b"\x1bOS",  // F4
};

// HID boot keycode -> [unshifted, shifted] ASCII, ported from TinyUSB HID_KEYCODE_TO_ASCII
// a 0 entry means non-printable / unhandled

#[rustfmt::skip]
pub static KEYCODE_TO_ASCII: [[u8; 2]; 128] = [
    [0, 0],                 // 0x00
    [0, 0],                 // 0x01
    [0, 0],                 // 0x02
    [0, 0],                 // 0x03
    [b'a', b'A'],           // 0x04
    [b'b', b'B'],           // 0x05
    [b'c', b'C'],           // 0x06
    [b'd', b'D'],           // 0x07
    [b'e', b'E'],           // 0x08
    [b'f', b'F'],           // 0x09
    [b'g', b'G'],           // 0x0a
    [b'h', b'H'],           // 0x0b
    [b'i', b'I'],           // 0x0c
    [b'j', b'J'],           // 0x0d
    [b'k', b'K'],           // 0x0e
    [b'l', b'L'],           // 0x0f
    [b'm', b'M'],           // 0x10
    [b'n', b'N'],           // 0x11
    [b'o', b'O'],           // 0x12
    [b'p', b'P'],           // 0x13
    [b'q', b'Q'],           // 0x14
    [b'r', b'R'],           // 0x15
    [b's', b'S'],           // 0x16
    [b't', b'T'],           // 0x17
    [b'u', b'U'],           // 0x18
    [b'v', b'V'],           // 0x19
    [b'w', b'W'],           // 0x1a
    [b'x', b'X'],           // 0x1b
    [b'y', b'Y'],           // 0x1c
    [b'z', b'Z'],           // 0x1d
    [b'1', b'!'],           // 0x1e
    [b'2', b'@'],           // 0x1f
    [b'3', b'#'],           // 0x20
    [b'4', b'$'],           // 0x21
    [b'5', b'%'],           // 0x22
    [b'6', b'^'],           // 0x23
    [b'7', b'&'],           // 0x24
    [b'8', b'*'],           // 0x25
    [b'9', b'('],           // 0x26
    [b'0', b')'],           // 0x27
    [b'\r', b'\r'],         // 0x28 Enter
    [b'\x1b', b'\x1b'],     // 0x29 Escape
    [b'\x08', b'\x08'],     // 0x2a Backspace
    [b'\t', b'\t'],         // 0x2b Tab
    [b' ', b' '],           // 0x2c Space
    [b'-', b'_'],           // 0x2d
    [b'=', b'+'],           // 0x2e
    [b'[', b'{'],           // 0x2f
    [b']', b'}'],           // 0x30
    [b'\\', b'|'],          // 0x31
    [b'#', b'~'],           // 0x32 Non-US # and ~
    [b';', b':'],           // 0x33
    [b'\'', b'"'],          // 0x34
    [b'`', b'~'],           // 0x35 Grave Accent and Tilde
    [b',', b'<'],           // 0x36
    [b'.', b'>'],           // 0x37
    [b'/', b'?'],           // 0x38
    [0, 0],                 // 0x39 Caps Lock
    [0, 0],                 // 0x3a F1
    [0, 0],                 // 0x3b F2
    [0, 0],                 // 0x3c F3
    [0, 0],                 // 0x3d F4
    [0, 0],                 // 0x3e F5
    [0, 0],                 // 0x3f F6
    [0, 0],                 // 0x40 F7
    [0, 0],                 // 0x41 F8
    [0, 0],                 // 0x42 F9
    [0, 0],                 // 0x43 F10
    [0, 0],                 // 0x44 F11
    [0, 0],                 // 0x45 F12
    [0, 0],                 // 0x46 Print Screen
    [0, 0],                 // 0x47 Scroll Lock
    [0, 0],                 // 0x48 Pause
    [0, 0],                 // 0x49 Insert
    [0, 0],                 // 0x4a Home
    [0, 0],                 // 0x4b Page Up
    [0, 0],                 // 0x4c Delete
    [0, 0],                 // 0x4d End
    [0, 0],                 // 0x4e Page Down
    [0, 0],                 // 0x4f Arrow Right
    [0, 0],                 // 0x50 Arrow Left
    [0, 0],                 // 0x51 Arrow Down
    [0, 0],                 // 0x52 Arrow Up
    [0, 0],                 // 0x53 Num Lock
    [b'/', b'/'],           // 0x54 Keypad /
    [b'*', b'*'],           // 0x55 Keypad *
    [b'-', b'-'],           // 0x56 Keypad -
    [b'+', b'+'],           // 0x57 Keypad +
    [b'\r', b'\r'],         // 0x58 Keypad Enter
    [b'1', 0],              // 0x59 Keypad 1 End
    [b'2', 0],              // 0x5a Keypad 2 Down
    [b'3', 0],              // 0x5b Keypad 3 Page Down
    [b'4', 0],              // 0x5c Keypad 4 Left
    [b'5', b'5'],           // 0x5d Keypad 5
    [b'6', 0],              // 0x5e Keypad 6 Right
    [b'7', 0],              // 0x5f Keypad 7 Home
    [b'8', 0],              // 0x60 Keypad 8 Up
    [b'9', 0],              // 0x61 Keypad 9 Page Up
    [b'0', 0],              // 0x62 Keypad 0 Insert
    [b'.', 0],              // 0x63 Keypad . Delete
    [0, 0],                 // 0x64
    [0, 0],                 // 0x65
    [0, 0],                 // 0x66
    [b'=', b'='],           // 0x67 Keypad =
    [0, 0],                 // 0x68
    [0, 0],                 // 0x69
    [0, 0],                 // 0x6a
    [0, 0],                 // 0x6b
    [0, 0],                 // 0x6c
    [0, 0],                 // 0x6d
    [0, 0],                 // 0x6e
    [0, 0],                 // 0x6f
    [0, 0],                 // 0x70
    [0, 0],                 // 0x71
    [0, 0],                 // 0x72
    [0, 0],                 // 0x73
    [0, 0],                 // 0x74
    [0, 0],                 // 0x75
    [0, 0],                 // 0x76
    [0, 0],                 // 0x77
    [0, 0],                 // 0x78
    [0, 0],                 // 0x79
    [0, 0],                 // 0x7a
    [0, 0],                 // 0x7b
    [0, 0],                 // 0x7c
    [0, 0],                 // 0x7d
    [0, 0],                 // 0x7e
    [0, 0],                 // 0x7f
];
