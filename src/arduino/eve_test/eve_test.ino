#include <Arduino.h>
#include <FreeRTOS.h>
#include <task.h>

#include "display.h"
#include "host.h"
#include "keyboard.h"
#include "logging.h"
#include "terminal.h"

void setup() {
  displayInit();
  terminalInit();
  hostInit();
  kbdInit();
  logInit();

  TaskHandle_t displayHandle;
  TaskHandle_t hostHandle;
  TaskHandle_t kbdHandle;
  TaskHandle_t logHandle;
  TaskHandle_t terminalHandle;

  xTaskCreate(displayTask, "displayTask", 1024, nullptr, 1, &displayHandle);
  xTaskCreate(hostTask, "hostTask", 1024, nullptr, 1, &hostHandle);
  xTaskCreate(kbdTask, "kbdTask", 1024, nullptr, 1, &kbdHandle);
  xTaskCreate(logTask, "logTask", 1024, nullptr, 1, &logHandle);
  xTaskCreate(terminalTask, "terminalTask", 1024, nullptr, 1, &terminalHandle);

  // set which cores the tasks run on
  // usb on core 1, everything else on core 0
  vTaskCoreAffinitySet(displayHandle, 1 << 0);
  vTaskCoreAffinitySet(hostHandle, 1 << 0);
  vTaskCoreAffinitySet(logHandle, 1 << 0);
  vTaskCoreAffinitySet(terminalHandle, 1 << 0);

  vTaskCoreAffinitySet(kbdHandle, 1 << 1);

  // loop forever
  vTaskStartScheduler();
}

void loop() {}