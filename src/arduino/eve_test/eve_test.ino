#include <Arduino.h>
#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/spi.h"
#include "hardware/gpio.h"
#include "EVE.h"

#define EVE_PD 6
#define EVE_CS 9
#define SPI1_MISO_PIN 8
#define SPI1_MOSI_PIN 15
#define SPI1_SCK_PIN 14

// -- test ---

// ANSI color code to TEXTVGA attribute mapping
// index is ANSI color number (0-7 normal, 8-15 bright)
const uint8_t ansi_to_textvga[] = {
	0x00,  // 0  - black
	0x08,  // 1  - red
	0x02,  // 2  - green
	0x0A,  // 3  - yellow
	0x01,  // 4  - blue
	0x05,  // 5  - magenta
	0x03,  // 6  - cyan
	0x0F,  // 7  - white
	0x07,  // 8  - bright black (dark grey)
	0x0C,  // 9  - bright red
	0x06,  // 10 - bright green
	0x0E,  // 11 - bright yellow
	0x09,  // 12 - bright blue
	0x0D,  // 13 - bright magenta
	0x0B,  // 14 - bright cyan
	0x0F,  // 15 - bright white
};

#define TERM_COLS 60
#define TERM_ROWS 17
#define TERM_HANDLE 0

uint8_t screen[TERM_ROWS][TERM_COLS][2];

void term_clear() {
	for (int r = 0; r < TERM_ROWS; r++)
		for (int c = 0; c < TERM_COLS; c++) {
			screen[r][c][0] = ' ';
			screen[r][c][1] = 0x70;  // white on black
		}
}

void term_putc(int row, int col, char ch, uint8_t attr) {
	if (row < 0 || row >= TERM_ROWS || col < 0 || col >= TERM_COLS) return;
	screen[row][col][0] = ch;
	screen[row][col][1] = attr;
}

void term_puts(int row, int col, const char *str, uint8_t attr) {
	while (*str && col < TERM_COLS)
		term_putc(row, col++, *str++, attr);
}

void term_write_to_eve() {
	// flatten screen buffer into a single array
	uint8_t buf[TERM_ROWS * TERM_COLS * 2];
	int i = 0;
	for (int r = 0; r < TERM_ROWS; r++)
		for (int c = 0; c < TERM_COLS; c++) {
			buf[i++] = screen[r][c][0];  // char
			buf[i++] = screen[r][c][1];  // attr
		}

	// write header
	uint8_t hdr[3] = {
		(uint8_t)(((EVE_RAM_G >> 16) & 0xFF) | 0x80),
		(uint8_t)((EVE_RAM_G >> 8) & 0xFF),
		(uint8_t)(EVE_RAM_G & 0xFF)
	};

	gpio_put(EVE_CS, 0);
	sleep_us(10);
	spi_write_blocking(spi1, hdr, 3);
	spi_write_blocking(spi1, buf, sizeof(buf));
	gpio_put(EVE_CS, 1);
}

void term_render() {
	term_write_to_eve();
	delay(10);

	printf("RAM_G[0]=%02X RAM_G[1]=%02X RAM_G[2]=%02X RAM_G[3]=%02X\n",
	       eve_read8(EVE_RAM_G + 0),
	       eve_read8(EVE_RAM_G + 1),
	       eve_read8(EVE_RAM_G + 2),
	       eve_read8(EVE_RAM_G + 3));

	uint32_t cmd = EVE_RAM_CMD;

	int i = 0;
	eve_write32(EVE_RAM_DL + (i++ * 4), DL_CLEAR_RGB | 0x000000);
	eve_write32(EVE_RAM_DL + (i++ * 4), DL_CLEAR | CLR_COL | CLR_STN | CLR_TAG);
	eve_write32(EVE_RAM_DL + (i++ * 4), BITMAP_SOURCE(EVE_RAM_G));
	eve_write32(EVE_RAM_DL + (i++ * 4), BITMAP_HANDLE(15));
	eve_write32(EVE_RAM_DL + (i++ * 4), BITMAP_LAYOUT(EVE_TEXTVGA, TERM_COLS * 2, TERM_ROWS));
	eve_write32(EVE_RAM_DL + (i++ * 4), BITMAP_SIZE(EVE_NEAREST, EVE_BORDER, EVE_BORDER, TERM_COLS * 8, TERM_ROWS * 16));
	eve_write32(EVE_RAM_DL + (i++ * 4), BLEND_FUNC(EVE_ONE, EVE_ZERO));
	eve_write32(EVE_RAM_DL + (i++ * 4), BEGIN(EVE_BITMAPS));
	eve_write32(EVE_RAM_DL + (i++ * 4), VERTEX2F(0, 0));
	eve_write32(EVE_RAM_DL + (i++ * 4), END());
	eve_write32(EVE_RAM_DL + (i++ * 4), DL_DISPLAY);

	eve_write32(REG_DLSWAP, EVE_DLSWAP_FRAME);
}

// --- low level SPI ---

void eve_spi(uint8_t *buf, int len) {
	gpio_put(EVE_CS, 0);
	sleep_us(10);
	spi_write_read_blocking(spi1, buf, buf, len);
	gpio_put(EVE_CS, 1);
}

// --- command write (host commands) ---

void eve_cmd(uint8_t cmd) {
	uint8_t buf[3] = { cmd, 0x00, 0x00 };
	eve_spi(buf, 3);
}

void eve_cmd_write32(uint32_t *cmd, uint32_t val) {
	eve_write32(*cmd, val);
	*cmd += 4;
}

void eve_cmd_writestr(uint32_t *cmd, const char *str) {
	int i = 0;
	uint32_t word = 0;
	int shift = 0;
	while (true) {
		uint8_t c = str[i++];
		word |= (c << shift);
		shift += 8;
		if (shift == 32) {
			eve_write32(*cmd, word);
			*cmd += 4;
			word = 0;
			shift = 0;
		}
		if (c == 0) break;
	}
	if (shift > 0) {
		eve_write32(*cmd, word);
		*cmd += 4;
	}
}

// --- memory read ---

void eve_read(uint32_t addr, uint8_t *result, int data_len) {
	int tx_len = 4 + data_len;
	uint8_t tx[tx_len];
	uint8_t rx[tx_len];

	tx[0] = (addr >> 16) & 0xFF;
	tx[1] = (addr >> 8) & 0xFF;
	tx[2] = (addr >> 0) & 0xFF;
	tx[3] = 0x00;
	memset(tx + 4, 0, data_len);

	gpio_put(EVE_CS, 0);
	sleep_us(10);
	spi_write_read_blocking(spi1, tx, rx, tx_len);
	gpio_put(EVE_CS, 1);

	memcpy(result, rx + 4, data_len);
}

uint8_t eve_read8(uint32_t addr) {
	uint8_t buf[1];
	eve_read(addr, buf, 1);
	return buf[0];
}

uint16_t eve_read16(uint32_t addr) {
	uint8_t buf[2];
	eve_read(addr, buf, 2);
	return (uint16_t)buf[0] | ((uint16_t)buf[1] << 8);
}

uint32_t eve_read32(uint32_t addr) {
	uint8_t buf[4];
	eve_read(addr, buf, 4);
	return (uint32_t)buf[0] | ((uint32_t)buf[1] << 8) | ((uint32_t)buf[2] << 16) | ((uint32_t)buf[3] << 24);
}

// --- memory write ---

void eve_write8(uint32_t addr, uint8_t data) {
	uint8_t buf[4] = {
		(uint8_t)(((addr >> 16) & 0xFF) | 0x80),
		(uint8_t)((addr >> 8) & 0xFF),
		(uint8_t)((addr >> 0) & 0xFF),
		data
	};
	eve_spi(buf, 4);
}

void eve_write16(uint32_t addr, uint16_t data) {
	uint8_t buf[5] = {
		(uint8_t)(((addr >> 16) & 0xFF) | 0x80),
		(uint8_t)((addr >> 8) & 0xFF),
		(uint8_t)((addr >> 0) & 0xFF),
		(uint8_t)((data >> 0) & 0xFF),
		(uint8_t)((data >> 8) & 0xFF)
	};
	eve_spi(buf, 5);
}

void eve_write32(uint32_t addr, uint32_t data) {
	uint8_t buf[7] = {
		(uint8_t)(((addr >> 16) & 0xFF) | 0x80),
		(uint8_t)((addr >> 8) & 0xFF),
		(uint8_t)((addr >> 0) & 0xFF),
		(uint8_t)((data >> 0) & 0xFF),
		(uint8_t)((data >> 8) & 0xFF),
		(uint8_t)((data >> 16) & 0xFF),
		(uint8_t)((data >> 24) & 0xFF)
	};
	eve_spi(buf, 7);
}

// --- init ---

uint8_t eve_init(void) {
	uint8_t chipid = 0;
	uint16_t timeout = 0;

	// power cycle
	gpio_put(EVE_PD, 0);
	delay(6);
	gpio_put(EVE_PD, 1);
	delay(21);

// clock and start
#if defined(EVE_HAS_CRYSTAL)
	eve_cmd(EVE_CLKEXT);
#else
	eve_cmd(EVE_CLKINT);
#endif

	eve_cmd(EVE_ACTIVE);
	delay(40);

	// wait for chip id
	do {
		delay(1);
		chipid = eve_read8(REG_ID);
		timeout++;
		if (timeout > 400) return 0;
	} while (chipid != 0x7C);

	// wait for reset complete
	timeout = 0;
	while (0x00 != (eve_read8(REG_CPURESET) & 0x03)) {
		delay(1);
		timeout++;
		if (timeout > 50) return 0;
	}

	// backlight off
	eve_write8(REG_PWM_DUTY, 0);

	// display timing
	eve_write16(REG_HSIZE, EVE_HSIZE);
	eve_write16(REG_HCYCLE, EVE_HCYCLE);
	eve_write16(REG_HOFFSET, EVE_HOFFSET);
	eve_write16(REG_HSYNC0, EVE_HSYNC0);
	eve_write16(REG_HSYNC1, EVE_HSYNC1);
	eve_write16(REG_VSIZE, EVE_VSIZE);
	eve_write16(REG_VCYCLE, EVE_VCYCLE);
	eve_write16(REG_VOFFSET, EVE_VOFFSET);
	eve_write16(REG_VSYNC0, EVE_VSYNC0);
	eve_write16(REG_VSYNC1, EVE_VSYNC1);
	eve_write8(REG_SWIZZLE, EVE_SWIZZLE);
	eve_write8(REG_PCLK_POL, EVE_PCLKPOL);
	eve_write8(REG_CSPREAD, EVE_CSPREAD);

	// touch
	eve_write8(REG_TOUCH_MODE, EVE_TMODE_CONTINUOUS);
	eve_write16(REG_TOUCH_RZTHRESH, EVE_TOUCH_RZTHRESH);

	// audio off
	eve_write8(REG_VOL_PB, 0x00);
	eve_write8(REG_VOL_SOUND, 0x00);
	eve_write16(REG_SOUND, 0x6000);

	// basic display list
	eve_write32(EVE_RAM_DL, DL_CLEAR_RGB);
	eve_write32(EVE_RAM_DL + 4, DL_CLEAR | CLR_COL | CLR_STN | CLR_TAG);
	eve_write32(EVE_RAM_DL + 8, DL_DISPLAY);
	eve_write32(REG_DLSWAP, EVE_DLSWAP_FRAME);

	// enable display and pixel clock
	eve_write8(REG_GPIO, 0x80);
	eve_write8(REG_PCLK, EVE_PCLK);

	// backlight on at 25%
	eve_write8(REG_PWM_DUTY, 0x20);

	// wait for coprocessor
	timeout = 0;
	while (eve_read8(REG_CPURESET) != 0x00) {
		delay(1);
		timeout++;
		if (timeout > 4) break;
	}

	return 1;
}

// --- arduino setup/loop ---

void setup() {
	delay(2000);
	printf("boot\n");

	gpio_init(EVE_CS);
	gpio_set_dir(EVE_CS, GPIO_OUT);
	gpio_put(EVE_CS, 1);

	gpio_init(EVE_PD);
	gpio_set_dir(EVE_PD, GPIO_OUT);
	gpio_put(EVE_PD, 1);

	spi_init(spi1, 11000000);
	gpio_set_function(SPI1_SCK_PIN, GPIO_FUNC_SPI);
	gpio_set_function(SPI1_MOSI_PIN, GPIO_FUNC_SPI);
	gpio_set_function(SPI1_MISO_PIN, GPIO_FUNC_SPI);
	spi_set_format(spi1, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);

	if (eve_init()) {
		printf("EVE init ok\n");
	} else {
		printf("EVE init failed\n");
	}

	// wait for any previous display list to finish
	while (eve_read8(REG_DLSWAP) != EVE_DLSWAP_DONE)
		;

	term_clear();
	term_puts(0, 0, "white on blue", 0x1F);   // 0x10 = blue bg, 0x0F = white fg
	term_puts(1, 0, "white on red", 0x4F);    // 0x40 = red bg, 0x0F = white fg
	term_puts(2, 0, "white on green", 0x2F);  // 0x20 = green bg, 0x0F = white fg
	term_puts(3, 0, "black on white", 0x70);  // 0x70 = white bg, 0x00 = black fg
	term_render();
}

void loop() {
	delay(1000);
}