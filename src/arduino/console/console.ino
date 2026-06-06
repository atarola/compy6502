#include <Arduino.h>
#include <FreeRTOS.h>
#include <task.h>

#include "display.h"
#include "host.h"
#include "keyboard.h"
#include "logging.h"
#include "terminal.h"

TaskHandle_t displayHandle;
TaskHandle_t hostHandle;
TaskHandle_t kbdHandle;
TaskHandle_t logHandle;
TaskHandle_t terminalHandle;
TaskHandle_t usbHandle;
TaskHandle_t blinkHandle;

#define LED_PIN 13

void blinkTask(void *pvParameters) {
  (void) pvParameters;
  pinMode(LED_PIN, OUTPUT);
  for (;;) {
    digitalWrite(LED_PIN, HIGH);
    vTaskDelay(pdMS_TO_TICKS(500));
    digitalWrite(LED_PIN, LOW);
    vTaskDelay(pdMS_TO_TICKS(500));
  }
}

void usbTask(void *pvParameters) {
  (void) pvParameters;
  for (;;) {
    #if defined(ARDUINO_ARCH_CORE_MAINLOOP)
    tud_task(); // Keeps the USB stack alive
    #endif

    // Quick yield to prevent CPU starvation
    vTaskDelay(pdMS_TO_TICKS(2));
  }
}

void setup() {
  Serial.begin(9600);
  vTaskDelay(pdMS_TO_TICKS(10));

  logInit();
  displayInit();
  kbdInit();
  terminalInit();
  hostInit();

  xTaskCreate(displayTask, "displayTask", 2048, nullptr, 3, &displayHandle);
  xTaskCreate(kbdTask, "kbdTask", 2048, nullptr, 1, &kbdHandle);
  xTaskCreate(logTask, "logTask", 2048, nullptr, tskIDLE_PRIORITY + 1, &logHandle);
  xTaskCreate(usbTask, "usbTask", 2048, NULL, configMAX_PRIORITIES - 1, &usbHandle);
  xTaskCreate(blinkTask, "blinkTask", 1024, NULL, tskIDLE_PRIORITY + 1, &blinkHandle);
  xTaskCreate(hostTask, "hostTask", 2048, nullptr, 1, &hostHandle);
  xTaskCreate(terminalTask, "terminalTask", 4096, nullptr, 1, &terminalHandle);
}

void loop() {}
