#include <Arduino.h>
#include <queue.h>
#include <stdarg.h>
#include <stdio.h>

#include "logging.h"

QueueHandle_t logQueue = nullptr;

struct LogMessage {
  char text[64];
};

void logInit() {
  logQueue = xQueueCreate(16, sizeof(LogMessage));
}

void logTask(void *parameter) {
  Serial.begin(115200);
  delay(1000);

  LogMessage msg;

  for (;;) {
    if (xQueueReceive(logQueue, &msg, portMAX_DELAY) == pdTRUE) {
      if (Serial) {
        Serial.println(msg.text);
      }
    }
  }
}

void logMessage(const char *format, ...) {
  if (logQueue == nullptr) {
    return;
  }

  LogMessage msg;

  va_list args;
  va_start(args, format);
  vsnprintf(msg.text, sizeof(msg.text), format, args);
  va_end(args);

  xQueueSend(logQueue, &msg, 0);
}

