#include <Arduino.h>
#include <FreeRTOS.h>
#include <task.h>
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/spi.h"

#include "host.h"
#include "keyboard.h"
#include "logging.h"
#include "terminal.h"

#define SPI0_CS 1
#define SPI0_MISO_PIN 0
#define SPI0_MOSI_PIN 3
#define SPI0_SCK_PIN 2

enum StatusFlags : uint8_t {
  STATUS_KBD_READY = 0x01
};

enum class State {
  Idle,
  SendStatus,
  SendChar,
  ReceiveChar,
};

enum class Command : uint8_t {
  // process handling
  Nop = 0x00,
  ReadStatus = 0x01,

  // terminal handling
  GetChar = 0x20,
  PutChar = 0x21,
};

static State state;
static uint8_t txByte;
static uint8_t rxByte;

void hostInit() {
  txByte = 0;
  rxByte = 0;

  spi_init(spi0, 1000000);
  spi_set_format(spi0, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);
  spi_set_slave(spi0, true);
}

void enterSendStatus() {
  state = State::SendStatus;

  uint8_t status = 0;
  status |= kbdHasData() ? StatusFlags::STATUS_KBD_READY : 0;

  txByte = status;
}

void handleSendStatus() {
  state = State::Idle;
  txByte = 0;
}

void enterSendChar() {
  state = State::SendChar;

  if (!kbdNextByte(&txByte, 0)) {
    txByte = 0;
  }
}

void handleSendChar() {
  state = State::Idle;
  txByte = 0;
}

void enterReceiveChar() {
  state = State::ReceiveChar;
}

void handleReceiveChar() {
  terminalReceiveChar(&rxByte);
  txByte = 0;
  state = State::Idle;
}

void handleIdle() {
  switch (static_cast<Command>(rxByte)) {
    case Command::ReadStatus:
      enterSendStatus();
      break;

    case Command::GetChar:
      enterSendChar();
      break;

    case Command::PutChar:
      enterReceiveChar();
      break;

    default:
      txByte = 0;
      state = State::Idle;
      break;
  }
}

void processByte() {
  switch (state) {
    case State::Idle:
      handleIdle();
      break;

    case State::SendStatus:
      handleSendStatus();
      break;

    case State::SendChar:
      handleSendChar();
      break;

    case State::ReceiveChar:
      handleReceiveChar();
      break;

    default:
      break;
  }
}

void hostTask(void *parameter) {
  for (;;) {
    // grab the next keyboard keycode, and offer it to the 6502
    // spi_write_read_blocking(spi1, &txByte, &rxByte, 1);
    // processByte();
    if (kbdNextByte(&txByte, 0)) {
      logMessage("host: %c", txByte);
      terminalReceiveChar(&txByte);
      txByte = 0;
    }

    delay(100);
  }
}
