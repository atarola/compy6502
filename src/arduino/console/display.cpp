#include <Arduino.h>
#include <FreeRTOS.h>
#include <task.h>
#include <queue.h>
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/spi.h"

#include "logging.h"
#include "eve.h"
#include "logging.h"

#define EVE_PD 6
#define EVE_CS 9
#define SPI1_MISO_PIN 8
#define SPI1_MOSI_PIN 15
#define SPI1_SCK_PIN 14

struct EveTxn {
  uint8_t *tx;
  size_t txLen;
  size_t rxLen;
  QueueHandle_t done;
};

static QueueHandle_t eveQueue = nullptr;
static uint8_t queueReady = 0;

static uint8_t eveInit();
static void eveTransaction(uint8_t *tx, size_t txLen, uint8_t *rx, size_t rxLen);
static void encodeAddr(uint8_t *buf, uint32_t addr, bool write);
static void encodeData(uint8_t *buf, uint32_t data, size_t len);
static void executeTxn(EveTxn *txn);

void displayInit() {
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

  eveQueue = xQueueCreate(32, sizeof(EveTxn));
  eveInit();
}

void displayTask(void *parameter) {
  queueReady = 1;
  EveTxn txn;

  for (;;) {
    if (xQueueReceive(eveQueue, &txn, portMAX_DELAY) == pdTRUE) {
      logMessage("got txn");
      executeTxn(&txn);
    }
  }
}

void displayCmd(uint8_t cmd) {
  uint8_t buf[3] = { cmd, 0x00, 0x00 };
  eveTransaction(buf, 3, nullptr, 0);
}

void displayWrite(uint32_t addr, uint8_t *data, size_t len) {
  uint8_t tx[3 + len];
  encodeAddr(tx, addr, true);
  memcpy(tx + 3, data, len);
  eveTransaction(tx, 3 + len, nullptr, 0);
}

void displayRead(uint32_t addr, uint8_t *out, size_t len) {
  uint8_t tx[4 + len];
  encodeAddr(tx, addr, false);
  tx[3] = 0x00;
  memset(tx + 4, 0, len);
  eveTransaction(tx, 4 + len, out, len);
}

void displayWrite8(uint32_t addr, uint8_t data) {
  displayWrite(addr, &data, 1);
}

void displayWrite16(uint32_t addr, uint16_t data) {
  uint8_t buf[2];
  encodeData(buf, data, 2);
  displayWrite(addr, buf, 2);
}

void displayWrite32(uint32_t addr, uint32_t data) {
  uint8_t buf[4];
  encodeData(buf, data, 4);
  displayWrite(addr, buf, 4);
}

uint8_t displayRead8(uint32_t addr) {
  uint8_t out;
  displayRead(addr, &out, 1);
  return out;
}

uint16_t displayRead16(uint32_t addr) {
  uint8_t buf[2];
  displayRead(addr, buf, 2);
  return (uint16_t)buf[0] | ((uint16_t)buf[1] << 8);
}

uint32_t displayRead32(uint32_t addr) {
  uint8_t buf[4];
  displayRead(addr, buf, 4);
  return (uint32_t)buf[0] | ((uint32_t)buf[1] << 8) | ((uint32_t)buf[2] << 16) | ((uint32_t)buf[3] << 24);
}

static void encodeAddr(uint8_t *buf, uint32_t addr, bool write) {
  buf[0] = ((addr >> 16) & 0x3F) | (write ? 0x80 : 0x00);
  buf[1] = (addr >> 8) & 0xFF;
  buf[2] = (addr >> 0) & 0xFF;
}

static void encodeData(uint8_t *buf, uint32_t data, size_t len) {
  for (size_t i = 0; i < len; i++) {
    buf[i] = (data >> (i * 8)) & 0xFF;
  }
}

static void eveTransaction(uint8_t *tx, size_t txLen, uint8_t *rx, size_t rxLen) {
  QueueHandle_t q = nullptr;

  if (rx != nullptr) {
    q = xQueueCreate(rxLen, sizeof(uint8_t));
  }

  EveTxn txn = { tx, txLen, rxLen, q };

  if (queueReady == 1) {
    xQueueSend(eveQueue, &txn, portMAX_DELAY);
  } else {
    executeTxn(&txn);
  }

  if (q == nullptr) {
    return;
  }

  for (size_t i = 0; i < rxLen; i++) {
    xQueueReceive(q, &rx[i], portMAX_DELAY);
  }

  vQueueDelete(q);
}

static void executeTxn(EveTxn *txn) {
  uint8_t rx[txn->txLen];

  gpio_put(EVE_CS, 0);
  sleep_us(10);
  spi_write_read_blocking(spi1, txn->tx, rx, txn->txLen);
  gpio_put(EVE_CS, 1);

  if (txn->done == nullptr) {
    return;
  }

  size_t offset = txn->txLen - txn->rxLen;
  for (size_t i = 0; i < txn->rxLen; i++) {
    xQueueSend(txn->done, &rx[offset + i], portMAX_DELAY);
  }
}

static uint8_t eveInit(void) {
  uint8_t chipid = 0;
  uint16_t timeout = 0;

  // power cycle
  gpio_put(EVE_PD, 0);
  vTaskDelay(pdMS_TO_TICKS(6)); 

  gpio_put(EVE_PD, 1);
  vTaskDelay(pdMS_TO_TICKS(21)); 

  // clock and start
  displayCmd(EVE_CLKEXT);
  displayCmd(EVE_ACTIVE);
  vTaskDelay(pdMS_TO_TICKS(40)); 

  // wait for chip id
  do {
    vTaskDelay(pdMS_TO_TICKS(1)); 
    chipid = displayRead8(REG_ID);
    logMessage("chipid=%02X", chipid);
    timeout++;
    if (timeout > 400) return 0;
  } while (chipid != 0x7C);

  // wait for reset complete
  timeout = 0;
  while (0x00 != (displayRead8(REG_CPURESET) & 0x03)) {
    vTaskDelay(pdMS_TO_TICKS(1)); 
    timeout++;
    if (timeout > 50) return 0;
  }

  // backlight off
  displayWrite8(REG_PWM_DUTY, 0);

  // display timing
  displayWrite16(REG_HSIZE, EVE_HSIZE);
  displayWrite16(REG_HCYCLE, EVE_HCYCLE);
  displayWrite16(REG_HOFFSET, EVE_HOFFSET);
  displayWrite16(REG_HSYNC0, EVE_HSYNC0);
  displayWrite16(REG_HSYNC1, EVE_HSYNC1);
  displayWrite16(REG_VSIZE, EVE_VSIZE);
  displayWrite16(REG_VCYCLE, EVE_VCYCLE);
  displayWrite16(REG_VOFFSET, EVE_VOFFSET);
  displayWrite16(REG_VSYNC0, EVE_VSYNC0);
  displayWrite16(REG_VSYNC1, EVE_VSYNC1);
  displayWrite8(REG_SWIZZLE, EVE_SWIZZLE);
  displayWrite8(REG_PCLK_POL, EVE_PCLKPOL);
  displayWrite8(REG_CSPREAD, EVE_CSPREAD);

  // touch
  displayWrite8(REG_TOUCH_MODE, EVE_TMODE_CONTINUOUS);
  displayWrite16(REG_TOUCH_RZTHRESH, EVE_TOUCH_RZTHRESH);

  // audio off
  displayWrite8(REG_VOL_PB, 0x00);
  displayWrite8(REG_VOL_SOUND, 0x00);
  displayWrite16(REG_SOUND, 0x6000);

  // basic display list
  displayWrite32(EVE_RAM_DL, DL_CLEAR_RGB);
  displayWrite32(EVE_RAM_DL + 4, DL_CLEAR | CLR_COL | CLR_STN | CLR_TAG);
  displayWrite32(EVE_RAM_DL + 8, DL_DISPLAY);
  displayWrite32(REG_DLSWAP, EVE_DLSWAP_FRAME);

  // enable display and pixel clock
  displayWrite8(REG_GPIO, 0x80);
  displayWrite8(REG_PCLK, EVE_PCLK);

  // backlight on at 25%
  displayWrite8(REG_PWM_DUTY, 0x20);

  // wait for coprocessor
  timeout = 0;
  while (displayRead8(REG_CPURESET) != 0x00) {
    vTaskDelay(pdMS_TO_TICKS(1)); 
    timeout++;
    if (timeout > 4) break;
  } 

  return 1;
}
