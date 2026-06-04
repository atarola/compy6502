/*
@file    EVE.h
@brief   Contains FT80x API definitions
@version 4.0
@date    2020-04-15
@author  Rudolph Riedel
*/

#pragma once

/* Display list defines */
#define DL_CLEAR        0x26000000UL
#define DL_CLEAR_RGB    0x02000000UL
#define DL_COLOR_RGB    0x04000000UL
#define DL_POINT_SIZE   0x0D000000UL
#define DL_END          0x21000000UL
#define DL_BEGIN        0x1F000000UL
#define DL_DISPLAY      0x00000000UL

#define CLR_COL         0x4
#define CLR_STN         0x2
#define CLR_TAG         0x1

/* Host commands */
#define EVE_ACTIVE      0x00
#define EVE_STANDBY     0x41
#define EVE_SLEEP       0x42
#define EVE_PWRDOWN     0x50
#define EVE_CLKEXT      0x44
#define EVE_CLKINT      0x48
#define EVE_CORERST     0x68
#define EVE_CLK48M      0x62
#define EVE_CLK36M      0x61

/* Graphics comparisons */
#define EVE_NEVER       0UL
#define EVE_LESS        1UL
#define EVE_LEQUAL      2UL
#define EVE_GREATER     3UL
#define EVE_GEQUAL      4UL
#define EVE_EQUAL       5UL
#define EVE_NOTEQUAL    6UL
#define EVE_ALWAYS      7UL

/* Bitmap formats */
#define EVE_ARGB1555    0UL
#define EVE_L1          1UL
#define EVE_L4          2UL
#define EVE_L8          3UL
#define EVE_RGB332      4UL
#define EVE_ARGB2       5UL
#define EVE_ARGB4       6UL
#define EVE_RGB565      7UL
#define EVE_PALETTED    8UL
#define EVE_TEXT8X8     9UL
#define EVE_TEXTVGA     10UL
#define EVE_BARGRAPH    11UL

/* Bitmap filter types */
#define EVE_NEAREST     0UL
#define EVE_BILINEAR    1UL

/* Bitmap wrap types */
#define EVE_BORDER      0UL
#define EVE_REPEAT      1UL

/* Stencil defines */
#define EVE_KEEP        1UL
#define EVE_REPLACE     2UL
#define EVE_INCR        3UL
#define EVE_DECR        4UL
#define EVE_INVERT      5UL

/* Display list swap */
#define EVE_DLSWAP_DONE     0UL
#define EVE_DLSWAP_LINE     1UL
#define EVE_DLSWAP_FRAME    2UL

/* Interrupt bits */
#define EVE_INT_SWAP        0x01
#define EVE_INT_TOUCH       0x02
#define EVE_INT_TAG         0x04
#define EVE_INT_SOUND       0x08
#define EVE_INT_PLAYBACK    0x10
#define EVE_INT_CMDEMPTY    0x20
#define EVE_INT_CMDFLAG     0x40
#define EVE_INT_CONVCOMPLETE 0x80

/* Touch mode */
#define EVE_TMODE_OFF           0
#define EVE_TMODE_ONESHOT       1
#define EVE_TMODE_FRAME         2
#define EVE_TMODE_CONTINUOUS    3

/* Alpha blending */
#define EVE_ZERO                0UL
#define EVE_ONE                 1UL
#define EVE_SRC_ALPHA           2UL
#define EVE_DST_ALPHA           3UL
#define EVE_ONE_MINUS_SRC_ALPHA 4UL
#define EVE_ONE_MINUS_DST_ALPHA 5UL

/* Graphics primitives */
#define EVE_BITMAPS         1UL
#define EVE_POINTS          2UL
#define EVE_LINES           3UL
#define EVE_LINE_STRIP      4UL
#define EVE_EDGE_STRIP_R    5UL
#define EVE_EDGE_STRIP_L    6UL
#define EVE_EDGE_STRIP_A    7UL
#define EVE_EDGE_STRIP_B    8UL
#define EVE_RECTS           9UL

/* Widget options */
#define EVE_OPT_MONO        1
#define EVE_OPT_NODL        2
#define EVE_OPT_FLAT        256
#define EVE_OPT_CENTERX     512
#define EVE_OPT_CENTERY     1024
#define EVE_OPT_CENTER      (EVE_OPT_CENTERX | EVE_OPT_CENTERY)
#define EVE_OPT_NOBACK      4096
#define EVE_OPT_NOTICKS     8192
#define EVE_OPT_NOHM        16384
#define EVE_OPT_NOPOINTER   16384
#define EVE_OPT_NOSECS      32768
#define EVE_OPT_NOHANDS     49152
#define EVE_OPT_RIGHTX      2048
#define EVE_OPT_SIGNED      256

/* Font defines */
#define EVE_NUMCHAR_PERFONT     (128L)
#define EVE_FONT_TABLE_SIZE     (148L)
#define EVE_FONT_TABLE_POINTER  (0xFFFFCUL)

/* Audio sample types */
#define EVE_LINEAR_SAMPLES  0UL
#define EVE_ULAW_SAMPLES    1UL
#define EVE_ADPCM_SAMPLES   2UL

/* Synthesized sound */
#define EVE_SILENCE         0x00
#define EVE_SQUAREWAVE      0x01
#define EVE_SINEWAVE        0x02
#define EVE_SAWTOOTH        0x03
#define EVE_TRIANGLE        0x04
#define EVE_BEEPING         0x05
#define EVE_ALARM           0x06
#define EVE_WARBLE          0x07
#define EVE_CAROUSEL        0x08
#define EVE_PIPS(n)         (0x0F + (n))
#define EVE_HARP            0x40
#define EVE_XYLOPHONE       0x41
#define EVE_TUBA            0x42
#define EVE_GLOCKENSPIEL    0x43
#define EVE_ORGAN           0x44
#define EVE_TRUMPET         0x45
#define EVE_PIANO           0x46
#define EVE_CHIMES          0x47
#define EVE_MUSICBOX        0x48
#define EVE_BELL            0x49
#define EVE_CLICK           0x50
#define EVE_SWITCH          0x51
#define EVE_COWBELL         0x52
#define EVE_NOTCH           0x53
#define EVE_HIHAT           0x54
#define EVE_KICKDRUM        0x55
#define EVE_POP             0x56
#define EVE_CLACK           0x57
#define EVE_CHACK           0x58
#define EVE_MUTE            0x60
#define EVE_UNMUTE          0x61

/* MIDI notes */
#define EVE_MIDI_A0   21
#define EVE_MIDI_A_0  22
#define EVE_MIDI_B0   23
#define EVE_MIDI_C1   24
#define EVE_MIDI_C_1  25
#define EVE_MIDI_D1   26
#define EVE_MIDI_D_1  27
#define EVE_MIDI_E1   28
#define EVE_MIDI_F1   29
#define EVE_MIDI_F_1  30
#define EVE_MIDI_G1   31
#define EVE_MIDI_G_1  32
#define EVE_MIDI_A1   33
#define EVE_MIDI_A_1  34
#define EVE_MIDI_B1   35
#define EVE_MIDI_C2   36
#define EVE_MIDI_C_2  37
#define EVE_MIDI_D2   38
#define EVE_MIDI_D_2  39
#define EVE_MIDI_E2   40
#define EVE_MIDI_F2   41
#define EVE_MIDI_F_2  42
#define EVE_MIDI_G2   43
#define EVE_MIDI_G_2  44
#define EVE_MIDI_A2   45
#define EVE_MIDI_A_2  46
#define EVE_MIDI_B2   47
#define EVE_MIDI_C3   48
#define EVE_MIDI_C_3  49
#define EVE_MIDI_D3   50
#define EVE_MIDI_D_3  51
#define EVE_MIDI_E3   52
#define EVE_MIDI_F3   53
#define EVE_MIDI_F_3  54
#define EVE_MIDI_G3   55
#define EVE_MIDI_G_3  56
#define EVE_MIDI_A3   57
#define EVE_MIDI_A_3  58
#define EVE_MIDI_B3   59
#define EVE_MIDI_C4   60
#define EVE_MIDI_C_4  61
#define EVE_MIDI_D4   62
#define EVE_MIDI_D_4  63
#define EVE_MIDI_E4   64
#define EVE_MIDI_F4   65
#define EVE_MIDI_F_4  66
#define EVE_MIDI_G4   67
#define EVE_MIDI_G_4  68
#define EVE_MIDI_A4   69
#define EVE_MIDI_A_4  70
#define EVE_MIDI_B4   71
#define EVE_MIDI_C5   72
#define EVE_MIDI_C_5  73
#define EVE_MIDI_D5   74
#define EVE_MIDI_D_5  75
#define EVE_MIDI_E5   76
#define EVE_MIDI_F5   77
#define EVE_MIDI_F_5  78
#define EVE_MIDI_G5   79
#define EVE_MIDI_G_5  80
#define EVE_MIDI_A5   81
#define EVE_MIDI_A_5  82
#define EVE_MIDI_B5   83
#define EVE_MIDI_C6   84
#define EVE_MIDI_C_6  85
#define EVE_MIDI_D6   86
#define EVE_MIDI_D_6  87
#define EVE_MIDI_E6   88
#define EVE_MIDI_F6   89
#define EVE_MIDI_F_6  90
#define EVE_MIDI_G6   91
#define EVE_MIDI_G_6  92
#define EVE_MIDI_A6   93
#define EVE_MIDI_A_6  94
#define EVE_MIDI_B6   95
#define EVE_MIDI_C7   96
#define EVE_MIDI_C_7  97
#define EVE_MIDI_D7   98
#define EVE_MIDI_D_7  99
#define EVE_MIDI_E7   100
#define EVE_MIDI_F7   101
#define EVE_MIDI_F_7  102
#define EVE_MIDI_G7   103
#define EVE_MIDI_G_7  104
#define EVE_MIDI_A7   105
#define EVE_MIDI_A_7  106
#define EVE_MIDI_B7   107
#define EVE_MIDI_C8   108

/* GPIO bits */
#define EVE_GPIO0   0
#define EVE_GPIO1   1
#define EVE_GPIO7   7

/* Display rotation */
#define EVE_DISPLAY_0   0
#define EVE_DISPLAY_180 1

/* Commands */
#define CMD_APPEND      0xFFFFFF1E
#define CMD_BGCOLOR     0xFFFFFF09
#define CMD_BUTTON      0xFFFFFF0D
#define CMD_CALIBRATE   0xFFFFFF15
#define CMD_CLOCK       0xFFFFFF14
#define CMD_COLDSTART   0xFFFFFF32
#define CMD_DIAL        0xFFFFFF2D
#define CMD_DLSTART     0xFFFFFF00
#define CMD_FGCOLOR     0xFFFFFF0A
#define CMD_GAUGE       0xFFFFFF13
#define CMD_GETMATRIX   0xFFFFFF33
#define CMD_GETPROPS    0xFFFFFF25
#define CMD_GETPTR      0xFFFFFF23
#define CMD_GRADCOLOR   0xFFFFFF34
#define CMD_GRADIENT    0xFFFFFF0B
#define CMD_INFLATE     0xFFFFFF22
#define CMD_INTERRUPT   0xFFFFFF02
#define CMD_KEYS        0xFFFFFF0E
#define CMD_LOADIDENTITY 0xFFFFFF26
#define CMD_LOADIMAGE   0xFFFFFF24
#define CMD_LOGO        0xFFFFFF31
#define CMD_MEMCPY      0xFFFFFF1D
#define CMD_MEMCRC      0xFFFFFF18
#define CMD_MEMSET      0xFFFFFF1B
#define CMD_MEMWRITE    0xFFFFFF1A
#define CMD_MEMZERO     0xFFFFFF1C
#define CMD_NUMBER      0xFFFFFF2E
#define CMD_PROGRESS    0xFFFFFF0F
#define CMD_REGREAD     0xFFFFFF19
#define CMD_ROTATE      0xFFFFFF29
#define CMD_SCALE       0xFFFFFF28
#define CMD_SCREENSAVER 0xFFFFFF2F
#define CMD_SCROLLBAR   0xFFFFFF11
#define CMD_SETFONT     0xFFFFFF2B
#define CMD_SETMATRIX   0xFFFFFF2A
#define CMD_SKETCH      0xFFFFFF30
#define CMD_SLIDER      0xFFFFFF10
#define CMD_SNAPSHOT    0xFFFFFF1F
#define CMD_SPINNER     0xFFFFFF16
#define CMD_STOP        0xFFFFFF17
#define CMD_SWAP        0xFFFFFF01
#define CMD_TEXT        0xFFFFFF0C
#define CMD_TOGGLE      0xFFFFFF12
#define CMD_TRACK       0xFFFFFF2C
#define CMD_TRANSLATE   0xFFFFFF27

/* Graphics macros */
#define ALPHA_FUNC(func,ref) ((9UL<<24)|(((func)&7UL)<<8)|(((ref)&255UL)<<0))
#define BEGIN(prim) ((31UL<<24)|(((prim)&15UL)<<0))
#define BITMAP_HANDLE(handle) ((5UL<<24)|(((handle)&31UL)<<0))
#define BITMAP_LAYOUT(format,linestride,height) ((7UL<<24)|(((format)&31UL)<<19)|(((linestride)&1023UL)<<9)|(((height)&511UL)<<0))
#define BITMAP_SIZE(filter,wrapx,wrapy,width,height) ((8UL<<24)|(((filter)&1UL)<<20)|(((wrapx)&1UL)<<19)|(((wrapy)&1UL)<<18)|(((width)&511UL)<<9)|(((height)&511UL)<<0))
#define BITMAP_SOURCE(addr) ((1UL<<24)|(((addr)&1048575UL)<<0))
#define BITMAP_TRANSFORM_A(a) ((21UL<<24)|(((a)&131071UL)<<0))
#define BITMAP_TRANSFORM_B(b) ((22UL<<24)|(((b)&131071UL)<<0))
#define BITMAP_TRANSFORM_C(c) ((23UL<<24)|(((c)&16777215UL)<<0))
#define BITMAP_TRANSFORM_D(d) ((24UL<<24)|(((d)&131071UL)<<0))
#define BITMAP_TRANSFORM_E(e) ((25UL<<24)|(((e)&131071UL)<<0))
#define BITMAP_TRANSFORM_F(f) ((26UL<<24)|(((f)&16777215UL)<<0))
#define BLEND_FUNC(src,dst) ((11UL<<24)|(((src)&7UL)<<3)|(((dst)&7UL)<<0))
#define CALL(dest) ((29UL<<24)|(((dest)&65535UL)<<0))
#define CELL(cell) ((6UL<<24)|(((cell)&127UL)<<0))
#define CLEAR(c,s,t) ((38UL<<24)|(((c)&1UL)<<2)|(((s)&1UL)<<1)|(((t)&1UL)<<0))
#define CLEAR_COLOR_A(alpha) ((15UL<<24)|(((alpha)&255UL)<<0))
#define CLEAR_COLOR_RGB(red,green,blue) ((2UL<<24)|(((red)&255UL)<<16)|(((green)&255UL)<<8)|(((blue)&255UL)<<0))
#define CLEAR_STENCIL(s) ((17UL<<24)|(((s)&255UL)<<0))
#define CLEAR_TAG(s) ((18UL<<24)|(((s)&255UL)<<0))
#define COLOR_A(alpha) ((16UL<<24)|(((alpha)&255UL)<<0))
#define COLOR_MASK(r,g,b,a) ((32UL<<24)|(((r)&1UL)<<3)|(((g)&1UL)<<2)|(((b)&1UL)<<1)|(((a)&1UL)<<0))
#define COLOR_RGB(red,green,blue) ((4UL<<24)|(((red)&255UL)<<16)|(((green)&255UL)<<8)|(((blue)&255UL)<<0))
#define END() ((33UL<<24))
#define JUMP(dest) ((30UL<<24)|(((dest)&65535UL)<<0))
#define LINE_WIDTH(width) ((14UL<<24)|(((width)&4095UL)<<0))
#define MACRO(m) ((37UL<<24)|(((m)&1UL)<<0))
#define POINT_SIZE(size) ((13UL<<24)|(((size)&8191UL)<<0))
#define RESTORE_CONTEXT() ((35UL<<24))
#define RETURN() ((36UL<<24))
#define SAVE_CONTEXT() ((34UL<<24))
#define SCISSOR_SIZE(width,height) ((28UL<<24)|(((width)&1023UL)<<10)|(((height)&1023UL)<<0))
#define SCISSOR_XY(x,y) ((27UL<<24)|(((x)&511UL)<<9)|(((y)&511UL)<<0))
#define STENCIL_FUNC(func,ref,mask) ((10UL<<24)|(((func)&7UL)<<16)|(((ref)&255UL)<<8)|(((mask)&255UL)<<0))
#define STENCIL_MASK(mask) ((19UL<<24)|(((mask)&255UL)<<0))
#define STENCIL_OP(sfail,spass) ((12UL<<24)|(((sfail)&7UL)<<3)|(((spass)&7UL)<<0))
#define TAG(s) ((3UL<<24)|(((s)&255UL)<<0))
#define TAG_MASK(mask) ((20UL<<24)|(((mask)&1UL)<<0))
#define VERTEX2F(x,y) ((1UL<<30)|(((x)&32767UL)<<15)|(((y)&32767UL)<<0))
#define VERTEX2II(x,y,handle,cell) ((2UL<<30)|(((x)&511UL)<<21)|(((y)&511UL)<<12)|(((handle)&31UL)<<7)|(((cell)&127UL)<<0))

/* FT80x memory definitions */
#define EVE_RAM_G           0x000000UL
#define EVE_ROM_CHIPID      0x0C0000UL
#define EVE_ROM_FONT        0x0BB23CUL
#define EVE_ROM_FONT_ADDR   0x0FFFFCUL
#define EVE_RAM_DL          0x100000UL
#define EVE_RAM_PAL         0x102000UL
#define EVE_RAM_CMD         0x108000UL
#define EVE_RAM_SCREENSHOT  0x1C2000UL

/* FT80x memory buffer sizes */
#define EVE_RAM_G_SIZE      256*1024L
#define EVE_CMDFIFO_SIZE    4*1024L
#define EVE_RAM_DL_SIZE     8*1024L
#define EVE_RAM_PAL_SIZE    1*1024L

/* FT80x register definitions */
#define REG_ID              0x102400UL
#define REG_FRAMES          0x102404UL
#define REG_CLOCK           0x102408UL
#define REG_FREQUENCY       0x10240CUL
#define REG_SCREENSHOT_EN   0x102410UL
#define REG_SCREENSHOT_Y    0x102414UL
#define REG_SCREENSHOT_START 0x102418UL
#define REG_CPURESET        0x10241CUL
#define REG_TAP_CRC         0x102420UL
#define REG_TAP_MASK        0x102424UL
#define REG_HCYCLE          0x102428UL
#define REG_HOFFSET         0x10242CUL
#define REG_HSIZE           0x102430UL
#define REG_HSYNC0          0x102434UL
#define REG_HSYNC1          0x102438UL
#define REG_VCYCLE          0x10243CUL
#define REG_VOFFSET         0x102440UL
#define REG_VSIZE           0x102444UL
#define REG_VSYNC0          0x102448UL
#define REG_VSYNC1          0x10244CUL
#define REG_DLSWAP          0x102450UL
#define REG_ROTATE          0x102454UL
#define REG_OUTBITS         0x102458UL
#define REG_DITHER          0x10245CUL
#define REG_SWIZZLE         0x102460UL
#define REG_CSPREAD         0x102464UL
#define REG_PCLK_POL        0x102468UL
#define REG_PCLK            0x10246CUL
#define REG_TAG_X           0x102470UL
#define REG_TAG_Y           0x102474UL
#define REG_TAG             0x102478UL
#define REG_VOL_PB          0x10247CUL
#define REG_VOL_SOUND       0x102480UL
#define REG_SOUND           0x102484UL
#define REG_PLAY            0x102488UL
#define REG_GPIO_DIR        0x10248CUL
#define REG_GPIO            0x102490UL
#define REG_INT_FLAGS       0x102498UL
#define REG_INT_EN          0x10249CUL
#define REG_INT_MASK        0x1024A0UL
#define REG_PLAYBACK_START  0x1024A4UL
#define REG_PLAYBACK_LENGTH 0x1024A8UL
#define REG_PLAYBACK_READPTR 0x1024ACUL
#define REG_PLAYBACK_FREQ   0x1024B0UL
#define REG_PLAYBACK_FORMAT 0x1024B4UL
#define REG_PLAYBACK_LOOP   0x1024B8UL
#define REG_PLAYBACK_PLAY   0x1024BCUL
#define REG_PWM_HZ          0x1024C0UL
#define REG_PWM_DUTY        0x1024C4UL
#define REG_MACRO_0         0x1024C8UL
#define REG_MACRO_1         0x1024CCUL
#define REG_SCREENSHOT_BUSY 0x1024D8UL
#define REG_CMD_READ        0x1024E4UL
#define REG_CMD_WRITE       0x1024E8UL
#define REG_CMD_DL          0x1024ECUL
#define REG_TOUCH_MODE      0x1024F0UL
#define REG_TOUCH_ADC_MODE  0x1024F4UL
#define REG_TOUCH_CHARGE    0x1024F8UL
#define REG_TOUCH_SETTLE    0x1024FCUL
#define REG_TOUCH_OVERSAMPLE 0x102500UL
#define REG_TOUCH_RZTHRESH  0x102504UL
#define REG_TOUCH_RAW_XY    0x102508UL
#define REG_TOUCH_RZ        0x10250CUL
#define REG_TOUCH_SCREEN_XY 0x102510UL
#define REG_TOUCH_TAG_XY    0x102514UL
#define REG_TOUCH_TAG       0x102518UL
#define REG_TOUCH_TRANSFORM_A 0x10251CUL
#define REG_TOUCH_TRANSFORM_B 0x102520UL
#define REG_TOUCH_TRANSFORM_C 0x102524UL
#define REG_TOUCH_TRANSFORM_D 0x102528UL
#define REG_TOUCH_TRANSFORM_E 0x10252CUL
#define REG_TOUCH_TRANSFORM_F 0x102530UL
#define REG_SCREENSHOT_READ 0x102554UL
#define REG_TRIM            0x10256CUL
#define REG_TOUCH_DIRECT_XY 0x102574UL
#define REG_TOUCH_DIRECT_Z1Z2 0x102578UL
#define REG_TRACKER         0x109000UL

#define EVE_HSIZE	(480L)
#define EVE_VSIZE	(272L)

#define EVE_VSYNC0	(0L)
#define EVE_VSYNC1	(10L)
#define EVE_VOFFSET	(12L)
#define EVE_VCYCLE	(286L)
#define EVE_HSYNC0	(0L)
#define EVE_HSYNC1	(41L)
#define EVE_HOFFSET	(43L)
#define EVE_HCYCLE 	(525L)
#define EVE_PCLKPOL	(1L)
#define EVE_SWIZZLE	(0L)
#define EVE_PCLK	(5L)
#define EVE_CSPREAD	(0L)
#define EVE_TOUCH_RZTHRESH (2000L)
#define EVE_HAS_CRYSTAL