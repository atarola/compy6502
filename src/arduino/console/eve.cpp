#include <Arduino.h>
#include <FreeRTOS.h>
#include <task.h>
#include <queue.h>
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/spi.h"

#include "eve.h"
#include "logging.h"

QueueHandle_t eveQueue = nullptr;

void eveInit() {
  spi_init(spi0, 1000000);
  spi_set_format(spi0, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);

  eveQueue = xQueueCreate(16, sizeof(uint8_t));
}

void eveTask(void *parameter) {
  uint8_t byte;
  
  for (;;) {
    if (xQueueReceive(eveQueue, &byte, portMAX_DELAY) == pdTRUE) {
      spi_write_blocking(spi0, &byte, 1);
    }
  }
}

void eveSendByte(uint8_t byte) {
  if (eveQueue == nullptr) {
    return;
  }

  xQueueSend(eveQueue, &byte, 0);
}