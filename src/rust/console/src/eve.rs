// Ported from EVE.h by Rudolph Riedel (v4.0, 2020-04-15)

// Host commands
pub const EVE_ACTIVE: u8 = 0x00;
pub const EVE_STANDBY: u8 = 0x41;
pub const EVE_SLEEP: u8 = 0x42;
pub const EVE_PWRDOWN: u8 = 0x50;
pub const EVE_CLKEXT: u8 = 0x44;
pub const EVE_CLKINT: u8 = 0x48;
pub const EVE_CORERST: u8 = 0x68;
pub const EVE_CLK48M: u8 = 0x62;
pub const EVE_CLK36M: u8 = 0x61;

// Display list defines
pub const DL_CLEAR: u32 = 0x26000000;
pub const DL_CLEAR_RGB: u32 = 0x02000000;
pub const DL_COLOR_RGB: u32 = 0x04000000;
pub const DL_POINT_SIZE: u32 = 0x0D000000;
pub const DL_END: u32 = 0x21000000;
pub const DL_BEGIN: u32 = 0x1F000000;
pub const DL_DISPLAY: u32 = 0x00000000;

pub const CLR_COL: u32 = 0x4;
pub const CLR_STN: u32 = 0x2;
pub const CLR_TAG: u32 = 0x1;

// Graphics comparisons
pub const EVE_NEVER: u32 = 0;
pub const EVE_LESS: u32 = 1;
pub const EVE_LEQUAL: u32 = 2;
pub const EVE_GREATER: u32 = 3;
pub const EVE_GEQUAL: u32 = 4;
pub const EVE_EQUAL: u32 = 5;
pub const EVE_NOTEQUAL: u32 = 6;
pub const EVE_ALWAYS: u32 = 7;

// Bitmap formats
pub const EVE_ARGB1555: u32 = 0;
pub const EVE_L1: u32 = 1;
pub const EVE_L4: u32 = 2;
pub const EVE_L8: u32 = 3;
pub const EVE_RGB332: u32 = 4;
pub const EVE_ARGB2: u32 = 5;
pub const EVE_ARGB4: u32 = 6;
pub const EVE_RGB565: u32 = 7;
pub const EVE_PALETTED: u32 = 8;
pub const EVE_TEXT8X8: u32 = 9;
pub const EVE_TEXTVGA: u32 = 10;
pub const EVE_BARGRAPH: u32 = 11;

// Bitmap filter types
pub const EVE_NEAREST: u32 = 0;
pub const EVE_BILINEAR: u32 = 1;

// Bitmap wrap types
pub const EVE_BORDER: u32 = 0;
pub const EVE_REPEAT: u32 = 1;

// Stencil defines
pub const EVE_KEEP: u32 = 1;
pub const EVE_REPLACE: u32 = 2;
pub const EVE_INCR: u32 = 3;
pub const EVE_DECR: u32 = 4;
pub const EVE_INVERT: u32 = 5;

// Display list swap
pub const EVE_DLSWAP_DONE: u32 = 0;
pub const EVE_DLSWAP_LINE: u32 = 1;
pub const EVE_DLSWAP_FRAME: u32 = 2;

// Interrupt bits
pub const EVE_INT_SWAP: u32 = 0x01;
pub const EVE_INT_TOUCH: u32 = 0x02;
pub const EVE_INT_TAG: u32 = 0x04;
pub const EVE_INT_SOUND: u32 = 0x08;
pub const EVE_INT_PLAYBACK: u32 = 0x10;
pub const EVE_INT_CMDEMPTY: u32 = 0x20;
pub const EVE_INT_CMDFLAG: u32 = 0x40;
pub const EVE_INT_CONVCOMPLETE: u32 = 0x80;

// Touch mode
pub const EVE_TMODE_OFF: u32 = 0;
pub const EVE_TMODE_ONESHOT: u32 = 1;
pub const EVE_TMODE_FRAME: u32 = 2;
pub const EVE_TMODE_CONTINUOUS: u32 = 3;

// Alpha blending
pub const EVE_ZERO: u32 = 0;
pub const EVE_ONE: u32 = 1;
pub const EVE_SRC_ALPHA: u32 = 2;
pub const EVE_DST_ALPHA: u32 = 3;
pub const EVE_ONE_MINUS_SRC_ALPHA: u32 = 4;
pub const EVE_ONE_MINUS_DST_ALPHA: u32 = 5;

// Graphics primitives
pub const EVE_BITMAPS: u32 = 1;
pub const EVE_POINTS: u32 = 2;
pub const EVE_LINES: u32 = 3;
pub const EVE_LINE_STRIP: u32 = 4;
pub const EVE_EDGE_STRIP_R: u32 = 5;
pub const EVE_EDGE_STRIP_L: u32 = 6;
pub const EVE_EDGE_STRIP_A: u32 = 7;
pub const EVE_EDGE_STRIP_B: u32 = 8;
pub const EVE_RECTS: u32 = 9;

// Widget options
pub const EVE_OPT_MONO: u32 = 1;
pub const EVE_OPT_NODL: u32 = 2;
pub const EVE_OPT_FLAT: u32 = 256;
pub const EVE_OPT_CENTERX: u32 = 512;
pub const EVE_OPT_CENTERY: u32 = 1024;
pub const EVE_OPT_CENTER: u32 = EVE_OPT_CENTERX | EVE_OPT_CENTERY;
pub const EVE_OPT_NOBACK: u32 = 4096;
pub const EVE_OPT_NOTICKS: u32 = 8192;
pub const EVE_OPT_NOHM: u32 = 16384;
pub const EVE_OPT_NOPOINTER: u32 = 16384;
pub const EVE_OPT_NOSECS: u32 = 32768;
pub const EVE_OPT_NOHANDS: u32 = 49152;
pub const EVE_OPT_RIGHTX: u32 = 2048;
pub const EVE_OPT_SIGNED: u32 = 256;

// Font defines
pub const EVE_NUMCHAR_PERFONT: u32 = 128;
pub const EVE_FONT_TABLE_SIZE: u32 = 148;
pub const EVE_FONT_TABLE_POINTER: u32 = 0xFFFFC;

// Audio sample types
pub const EVE_LINEAR_SAMPLES: u32 = 0;
pub const EVE_ULAW_SAMPLES: u32 = 1;
pub const EVE_ADPCM_SAMPLES: u32 = 2;

// Synthesized sound
pub const EVE_SILENCE: u8 = 0x00;
pub const EVE_SQUAREWAVE: u8 = 0x01;
pub const EVE_SINEWAVE: u8 = 0x02;
pub const EVE_SAWTOOTH: u8 = 0x03;
pub const EVE_TRIANGLE: u8 = 0x04;
pub const EVE_BEEPING: u8 = 0x05;
pub const EVE_ALARM: u8 = 0x06;
pub const EVE_WARBLE: u8 = 0x07;
pub const EVE_CAROUSEL: u8 = 0x08;
pub const fn eve_pips(n: u8) -> u8 {
    0x0F + n
}
pub const EVE_HARP: u8 = 0x40;
pub const EVE_XYLOPHONE: u8 = 0x41;
pub const EVE_TUBA: u8 = 0x42;
pub const EVE_GLOCKENSPIEL: u8 = 0x43;
pub const EVE_ORGAN: u8 = 0x44;
pub const EVE_TRUMPET: u8 = 0x45;
pub const EVE_PIANO: u8 = 0x46;
pub const EVE_CHIMES: u8 = 0x47;
pub const EVE_MUSICBOX: u8 = 0x48;
pub const EVE_BELL: u8 = 0x49;
pub const EVE_CLICK: u8 = 0x50;
pub const EVE_SWITCH: u8 = 0x51;
pub const EVE_COWBELL: u8 = 0x52;
pub const EVE_NOTCH: u8 = 0x53;
pub const EVE_HIHAT: u8 = 0x54;
pub const EVE_KICKDRUM: u8 = 0x55;
pub const EVE_POP: u8 = 0x56;
pub const EVE_CLACK: u8 = 0x57;
pub const EVE_CHACK: u8 = 0x58;
pub const EVE_MUTE: u8 = 0x60;
pub const EVE_UNMUTE: u8 = 0x61;

// MIDI notes
pub const EVE_MIDI_A0: u8 = 21;
pub const EVE_MIDI_A_0: u8 = 22;
pub const EVE_MIDI_B0: u8 = 23;
pub const EVE_MIDI_C1: u8 = 24;
pub const EVE_MIDI_C_1: u8 = 25;
pub const EVE_MIDI_D1: u8 = 26;
pub const EVE_MIDI_D_1: u8 = 27;
pub const EVE_MIDI_E1: u8 = 28;
pub const EVE_MIDI_F1: u8 = 29;
pub const EVE_MIDI_F_1: u8 = 30;
pub const EVE_MIDI_G1: u8 = 31;
pub const EVE_MIDI_G_1: u8 = 32;
pub const EVE_MIDI_A1: u8 = 33;
pub const EVE_MIDI_A_1: u8 = 34;
pub const EVE_MIDI_B1: u8 = 35;
pub const EVE_MIDI_C2: u8 = 36;
pub const EVE_MIDI_C_2: u8 = 37;
pub const EVE_MIDI_D2: u8 = 38;
pub const EVE_MIDI_D_2: u8 = 39;
pub const EVE_MIDI_E2: u8 = 40;
pub const EVE_MIDI_F2: u8 = 41;
pub const EVE_MIDI_F_2: u8 = 42;
pub const EVE_MIDI_G2: u8 = 43;
pub const EVE_MIDI_G_2: u8 = 44;
pub const EVE_MIDI_A2: u8 = 45;
pub const EVE_MIDI_A_2: u8 = 46;
pub const EVE_MIDI_B2: u8 = 47;
pub const EVE_MIDI_C3: u8 = 48;
pub const EVE_MIDI_C_3: u8 = 49;
pub const EVE_MIDI_D3: u8 = 50;
pub const EVE_MIDI_D_3: u8 = 51;
pub const EVE_MIDI_E3: u8 = 52;
pub const EVE_MIDI_F3: u8 = 53;
pub const EVE_MIDI_F_3: u8 = 54;
pub const EVE_MIDI_G3: u8 = 55;
pub const EVE_MIDI_G_3: u8 = 56;
pub const EVE_MIDI_A3: u8 = 57;
pub const EVE_MIDI_A_3: u8 = 58;
pub const EVE_MIDI_B3: u8 = 59;
pub const EVE_MIDI_C4: u8 = 60;
pub const EVE_MIDI_C_4: u8 = 61;
pub const EVE_MIDI_D4: u8 = 62;
pub const EVE_MIDI_D_4: u8 = 63;
pub const EVE_MIDI_E4: u8 = 64;
pub const EVE_MIDI_F4: u8 = 65;
pub const EVE_MIDI_F_4: u8 = 66;
pub const EVE_MIDI_G4: u8 = 67;
pub const EVE_MIDI_G_4: u8 = 68;
pub const EVE_MIDI_A4: u8 = 69;
pub const EVE_MIDI_A_4: u8 = 70;
pub const EVE_MIDI_B4: u8 = 71;
pub const EVE_MIDI_C5: u8 = 72;
pub const EVE_MIDI_C_5: u8 = 73;
pub const EVE_MIDI_D5: u8 = 74;
pub const EVE_MIDI_D_5: u8 = 75;
pub const EVE_MIDI_E5: u8 = 76;
pub const EVE_MIDI_F5: u8 = 77;
pub const EVE_MIDI_F_5: u8 = 78;
pub const EVE_MIDI_G5: u8 = 79;
pub const EVE_MIDI_G_5: u8 = 80;
pub const EVE_MIDI_A5: u8 = 81;
pub const EVE_MIDI_A_5: u8 = 82;
pub const EVE_MIDI_B5: u8 = 83;
pub const EVE_MIDI_C6: u8 = 84;
pub const EVE_MIDI_C_6: u8 = 85;
pub const EVE_MIDI_D6: u8 = 86;
pub const EVE_MIDI_D_6: u8 = 87;
pub const EVE_MIDI_E6: u8 = 88;
pub const EVE_MIDI_F6: u8 = 89;
pub const EVE_MIDI_F_6: u8 = 90;
pub const EVE_MIDI_G6: u8 = 91;
pub const EVE_MIDI_G_6: u8 = 92;
pub const EVE_MIDI_A6: u8 = 93;
pub const EVE_MIDI_A_6: u8 = 94;
pub const EVE_MIDI_B6: u8 = 95;
pub const EVE_MIDI_C7: u8 = 96;
pub const EVE_MIDI_C_7: u8 = 97;
pub const EVE_MIDI_D7: u8 = 98;
pub const EVE_MIDI_D_7: u8 = 99;
pub const EVE_MIDI_E7: u8 = 100;
pub const EVE_MIDI_F7: u8 = 101;
pub const EVE_MIDI_F_7: u8 = 102;
pub const EVE_MIDI_G7: u8 = 103;
pub const EVE_MIDI_G_7: u8 = 104;
pub const EVE_MIDI_A7: u8 = 105;
pub const EVE_MIDI_A_7: u8 = 106;
pub const EVE_MIDI_B7: u8 = 107;
pub const EVE_MIDI_C8: u8 = 108;

// GPIO bits
pub const EVE_GPIO0: u32 = 0;
pub const EVE_GPIO1: u32 = 1;
pub const EVE_GPIO7: u32 = 7;

// Display rotation
pub const EVE_DISPLAY_0: u32 = 0;
pub const EVE_DISPLAY_180: u32 = 1;

// Commands
pub const CMD_APPEND: u32 = 0xFFFFFF1E;
pub const CMD_BGCOLOR: u32 = 0xFFFFFF09;
pub const CMD_BUTTON: u32 = 0xFFFFFF0D;
pub const CMD_CALIBRATE: u32 = 0xFFFFFF15;
pub const CMD_CLOCK: u32 = 0xFFFFFF14;
pub const CMD_COLDSTART: u32 = 0xFFFFFF32;
pub const CMD_DIAL: u32 = 0xFFFFFF2D;
pub const CMD_DLSTART: u32 = 0xFFFFFF00;
pub const CMD_FGCOLOR: u32 = 0xFFFFFF0A;
pub const CMD_GAUGE: u32 = 0xFFFFFF13;
pub const CMD_GETMATRIX: u32 = 0xFFFFFF33;
pub const CMD_GETPROPS: u32 = 0xFFFFFF25;
pub const CMD_GETPTR: u32 = 0xFFFFFF23;
pub const CMD_GRADCOLOR: u32 = 0xFFFFFF34;
pub const CMD_GRADIENT: u32 = 0xFFFFFF0B;
pub const CMD_INFLATE: u32 = 0xFFFFFF22;
pub const CMD_INTERRUPT: u32 = 0xFFFFFF02;
pub const CMD_KEYS: u32 = 0xFFFFFF0E;
pub const CMD_LOADIDENTITY: u32 = 0xFFFFFF26;
pub const CMD_LOADIMAGE: u32 = 0xFFFFFF24;
pub const CMD_LOGO: u32 = 0xFFFFFF31;
pub const CMD_MEMCPY: u32 = 0xFFFFFF1D;
pub const CMD_MEMCRC: u32 = 0xFFFFFF18;
pub const CMD_MEMSET: u32 = 0xFFFFFF1B;
pub const CMD_MEMWRITE: u32 = 0xFFFFFF1A;
pub const CMD_MEMZERO: u32 = 0xFFFFFF1C;
pub const CMD_NUMBER: u32 = 0xFFFFFF2E;
pub const CMD_PROGRESS: u32 = 0xFFFFFF0F;
pub const CMD_REGREAD: u32 = 0xFFFFFF19;
pub const CMD_ROTATE: u32 = 0xFFFFFF29;
pub const CMD_SCALE: u32 = 0xFFFFFF28;
pub const CMD_SCREENSAVER: u32 = 0xFFFFFF2F;
pub const CMD_SCROLLBAR: u32 = 0xFFFFFF11;
pub const CMD_SETFONT: u32 = 0xFFFFFF2B;
pub const CMD_SETMATRIX: u32 = 0xFFFFFF2A;
pub const CMD_SKETCH: u32 = 0xFFFFFF30;
pub const CMD_SLIDER: u32 = 0xFFFFFF10;
pub const CMD_SNAPSHOT: u32 = 0xFFFFFF1F;
pub const CMD_SPINNER: u32 = 0xFFFFFF16;
pub const CMD_STOP: u32 = 0xFFFFFF17;
pub const CMD_SWAP: u32 = 0xFFFFFF01;
pub const CMD_TEXT: u32 = 0xFFFFFF0C;
pub const CMD_TOGGLE: u32 = 0xFFFFFF12;
pub const CMD_TRACK: u32 = 0xFFFFFF2C;
pub const CMD_TRANSLATE: u32 = 0xFFFFFF27;

// Graphics macros
pub const fn alpha_func(func: u32, reference: u32) -> u32 {
    (9 << 24) | ((func & 7) << 8) | (reference & 255)
}

pub const fn begin(prim: u32) -> u32 {
    (31 << 24) | (prim & 15)
}

pub const fn bitmap_handle(handle: u32) -> u32 {
    (5 << 24) | (handle & 31)
}

pub const fn bitmap_layout(format: u32, linestride: u32, height: u32) -> u32 {
    (7 << 24) | ((format & 31) << 19) | ((linestride & 1023) << 9) | (height & 511)
}

pub const fn bitmap_size(filter: u32, wrapx: u32, wrapy: u32, width: u32, height: u32) -> u32 {
    (8 << 24)
        | ((filter & 1) << 20)
        | ((wrapx & 1) << 19)
        | ((wrapy & 1) << 18)
        | ((width & 511) << 9)
        | (height & 511)
}

pub const fn bitmap_source(addr: u32) -> u32 {
    (1 << 24) | (addr & 1048575)
}

pub const fn bitmap_transform_a(a: u32) -> u32 {
    (21 << 24) | (a & 131071)
}

pub const fn bitmap_transform_b(b: u32) -> u32 {
    (22 << 24) | (b & 131071)
}

pub const fn bitmap_transform_c(c: u32) -> u32 {
    (23 << 24) | (c & 16777215)
}

pub const fn bitmap_transform_d(d: u32) -> u32 {
    (24 << 24) | (d & 131071)
}

pub const fn bitmap_transform_e(e: u32) -> u32 {
    (25 << 24) | (e & 131071)
}

pub const fn bitmap_transform_f(f: u32) -> u32 {
    (26 << 24) | (f & 16777215)
}

pub const fn blend_func(src: u32, dst: u32) -> u32 {
    (11 << 24) | ((src & 7) << 3) | (dst & 7)
}

pub const fn call(dest: u32) -> u32 {
    (29 << 24) | (dest & 65535)
}

pub const fn cell(cell: u32) -> u32 {
    (6 << 24) | (cell & 127)
}

pub const fn clear(c: u32, s: u32, t: u32) -> u32 {
    (38 << 24) | ((c & 1) << 2) | ((s & 1) << 1) | (t & 1)
}

pub const fn clear_color_a(alpha: u32) -> u32 {
    (15 << 24) | (alpha & 255)
}

pub const fn clear_color_rgb(red: u32, green: u32, blue: u32) -> u32 {
    (2 << 24) | ((red & 255) << 16) | ((green & 255) << 8) | (blue & 255)
}

pub const fn clear_stencil(s: u32) -> u32 {
    (17 << 24) | (s & 255)
}

pub const fn clear_tag(s: u32) -> u32 {
    (18 << 24) | (s & 255)
}

pub const fn color_a(alpha: u32) -> u32 {
    (16 << 24) | (alpha & 255)
}

pub const fn color_mask(r: u32, g: u32, b: u32, a: u32) -> u32 {
    (32 << 24) | ((r & 1) << 3) | ((g & 1) << 2) | ((b & 1) << 1) | (a & 1)
}

pub const fn color_rgb(red: u32, green: u32, blue: u32) -> u32 {
    (4 << 24) | ((red & 255) << 16) | ((green & 255) << 8) | (blue & 255)
}

pub const fn end() -> u32 {
    33 << 24
}

pub const fn jump(dest: u32) -> u32 {
    (30 << 24) | (dest & 65535)
}

pub const fn line_width(width: u32) -> u32 {
    (14 << 24) | (width & 4095)
}

pub const fn macro_(m: u32) -> u32 {
    (37 << 24) | (m & 1)
}

pub const fn point_size(size: u32) -> u32 {
    (13 << 24) | (size & 8191)
}

pub const fn restore_context() -> u32 {
    35 << 24
}

pub const fn return_() -> u32 {
    36 << 24
}

pub const fn save_context() -> u32 {
    34 << 24
}

pub const fn scissor_size(width: u32, height: u32) -> u32 {
    (28 << 24) | ((width & 1023) << 10) | (height & 1023)
}

pub const fn scissor_xy(x: u32, y: u32) -> u32 {
    (27 << 24) | ((x & 511) << 9) | (y & 511)
}

pub const fn stencil_func(func: u32, reference: u32, mask: u32) -> u32 {
    (10 << 24) | ((func & 7) << 16) | ((reference & 255) << 8) | (mask & 255)
}

pub const fn stencil_mask(mask: u32) -> u32 {
    (19 << 24) | (mask & 255)
}

pub const fn stencil_op(sfail: u32, spass: u32) -> u32 {
    (12 << 24) | ((sfail & 7) << 3) | (spass & 7)
}

pub const fn tag(s: u32) -> u32 {
    (3 << 24) | (s & 255)
}

pub const fn tag_mask(mask: u32) -> u32 {
    (20 << 24) | (mask & 1)
}

pub const fn vertex2f(x: u32, y: u32) -> u32 {
    (1 << 30) | ((x & 32767) << 15) | (y & 32767)
}

pub const fn vertex2ii(x: u32, y: u32, handle: u32, cell: u32) -> u32 {
    (2 << 30) | ((x & 511) << 21) | ((y & 511) << 12) | ((handle & 31) << 7) | (cell & 127)
}

// FT80x memory map
pub const EVE_RAM_G: u32 = 0x000000;
pub const EVE_ROM_CHIPID: u32 = 0x0C0000;
pub const EVE_ROM_FONT: u32 = 0x0BB23C;
pub const EVE_ROM_FONT_ADDR: u32 = 0x0FFFFC;
pub const EVE_RAM_DL: u32 = 0x100000;
pub const EVE_RAM_PAL: u32 = 0x102000;
pub const EVE_RAM_CMD: u32 = 0x108000;
pub const EVE_RAM_SCREENSHOT: u32 = 0x1C2000;

pub const EVE_RAM_G_SIZE: u32 = 256 * 1024;
pub const EVE_CMDFIFO_SIZE: u32 = 4 * 1024;
pub const EVE_RAM_DL_SIZE: u32 = 8 * 1024;
pub const EVE_RAM_PAL_SIZE: u32 = 1 * 1024;

// FT80x registers
pub const REG_ID: u32 = 0x102400;
pub const REG_FRAMES: u32 = 0x102404;
pub const REG_CLOCK: u32 = 0x102408;
pub const REG_FREQUENCY: u32 = 0x10240C;
pub const REG_SCREENSHOT_EN: u32 = 0x102410;
pub const REG_SCREENSHOT_Y: u32 = 0x102414;
pub const REG_SCREENSHOT_START: u32 = 0x102418;
pub const REG_CPURESET: u32 = 0x10241C;
pub const REG_TAP_CRC: u32 = 0x102420;
pub const REG_TAP_MASK: u32 = 0x102424;
pub const REG_HCYCLE: u32 = 0x102428;
pub const REG_HOFFSET: u32 = 0x10242C;
pub const REG_HSIZE: u32 = 0x102430;
pub const REG_HSYNC0: u32 = 0x102434;
pub const REG_HSYNC1: u32 = 0x102438;
pub const REG_VCYCLE: u32 = 0x10243C;
pub const REG_VOFFSET: u32 = 0x102440;
pub const REG_VSIZE: u32 = 0x102444;
pub const REG_VSYNC0: u32 = 0x102448;
pub const REG_VSYNC1: u32 = 0x10244C;
pub const REG_DLSWAP: u32 = 0x102450;
pub const REG_ROTATE: u32 = 0x102454;
pub const REG_OUTBITS: u32 = 0x102458;
pub const REG_DITHER: u32 = 0x10245C;
pub const REG_SWIZZLE: u32 = 0x102460;
pub const REG_CSPREAD: u32 = 0x102464;
pub const REG_PCLK_POL: u32 = 0x102468;
pub const REG_PCLK: u32 = 0x10246C;
pub const REG_TAG_X: u32 = 0x102470;
pub const REG_TAG_Y: u32 = 0x102474;
pub const REG_TAG: u32 = 0x102478;
pub const REG_VOL_PB: u32 = 0x10247C;
pub const REG_VOL_SOUND: u32 = 0x102480;
pub const REG_SOUND: u32 = 0x102484;
pub const REG_PLAY: u32 = 0x102488;
pub const REG_GPIO_DIR: u32 = 0x10248C;
pub const REG_GPIO: u32 = 0x102490;
pub const REG_INT_FLAGS: u32 = 0x102498;
pub const REG_INT_EN: u32 = 0x10249C;
pub const REG_INT_MASK: u32 = 0x1024A0;
pub const REG_PLAYBACK_START: u32 = 0x1024A4;
pub const REG_PLAYBACK_LENGTH: u32 = 0x1024A8;
pub const REG_PLAYBACK_READPTR: u32 = 0x1024AC;
pub const REG_PLAYBACK_FREQ: u32 = 0x1024B0;
pub const REG_PLAYBACK_FORMAT: u32 = 0x1024B4;
pub const REG_PLAYBACK_LOOP: u32 = 0x1024B8;
pub const REG_PLAYBACK_PLAY: u32 = 0x1024BC;
pub const REG_PWM_HZ: u32 = 0x1024C0;
pub const REG_PWM_DUTY: u32 = 0x1024C4;
pub const REG_MACRO_0: u32 = 0x1024C8;
pub const REG_MACRO_1: u32 = 0x1024CC;
pub const REG_SCREENSHOT_BUSY: u32 = 0x1024D8;
pub const REG_CMD_READ: u32 = 0x1024E4;
pub const REG_CMD_WRITE: u32 = 0x1024E8;
pub const REG_CMD_DL: u32 = 0x1024EC;
pub const REG_TOUCH_MODE: u32 = 0x1024F0;
pub const REG_TOUCH_ADC_MODE: u32 = 0x1024F4;
pub const REG_TOUCH_CHARGE: u32 = 0x1024F8;
pub const REG_TOUCH_SETTLE: u32 = 0x1024FC;
pub const REG_TOUCH_OVERSAMPLE: u32 = 0x102500;
pub const REG_TOUCH_RZTHRESH: u32 = 0x102504;
pub const REG_TOUCH_RAW_XY: u32 = 0x102508;
pub const REG_TOUCH_RZ: u32 = 0x10250C;
pub const REG_TOUCH_SCREEN_XY: u32 = 0x102510;
pub const REG_TOUCH_TAG_XY: u32 = 0x102514;
pub const REG_TOUCH_TAG: u32 = 0x102518;
pub const REG_TOUCH_TRANSFORM_A: u32 = 0x10251C;
pub const REG_TOUCH_TRANSFORM_B: u32 = 0x102520;
pub const REG_TOUCH_TRANSFORM_C: u32 = 0x102524;
pub const REG_TOUCH_TRANSFORM_D: u32 = 0x102528;
pub const REG_TOUCH_TRANSFORM_E: u32 = 0x10252C;
pub const REG_TOUCH_TRANSFORM_F: u32 = 0x102530;
pub const REG_SCREENSHOT_READ: u32 = 0x102554;
pub const REG_TRIM: u32 = 0x10256C;
pub const REG_TOUCH_DIRECT_XY: u32 = 0x102574;
pub const REG_TOUCH_DIRECT_Z1Z2: u32 = 0x102578;
pub const REG_TRACKER: u32 = 0x109000;

// Display timing
pub const EVE_HSIZE: u32 = 480;
pub const EVE_VSIZE: u32 = 272;
pub const EVE_VSYNC0: u32 = 0;
pub const EVE_VSYNC1: u32 = 10;
pub const EVE_VOFFSET: u32 = 12;
pub const EVE_VCYCLE: u32 = 286;
pub const EVE_HSYNC0: u32 = 0;
pub const EVE_HSYNC1: u32 = 41;
pub const EVE_HOFFSET: u32 = 43;
pub const EVE_HCYCLE: u32 = 525;
pub const EVE_PCLKPOL: u32 = 1;
pub const EVE_SWIZZLE: u32 = 0;
pub const EVE_PCLK: u32 = 5;
pub const EVE_CSPREAD: u32 = 0;
pub const EVE_TOUCH_RZTHRESH: u32 = 2000;
pub const EVE_HAS_CRYSTAL: bool = true;
