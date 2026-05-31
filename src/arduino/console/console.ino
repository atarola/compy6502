#include <Arduino.h>
#include <FreeRTOS.h>
#include <task.h>

#include "host.h"
#include "keyboard.h"
#include "logging.h"

void setup() {
  hostInit();
  kbdInit();
  logInit();

  TaskHandle_t hostHandle;
  TaskHandle_t kbdHandle;
  TaskHandle_t logHandle;

  xTaskCreate(kbdTask, "hostTask", 1024, nullptr, 1, &hostHandle);
  xTaskCreate(kbdTask, "kbdTask", 1024, nullptr, 1, &kbdHandle);
  xTaskCreate(logTask, "logTask", 1024, nullptr, 1, &logHandle);

  // set which cores the tasks run on
  // usb on core 1, everything else on core 0
  vTaskCoreAffinitySet(hostHandle, 1 << 0);
  vTaskCoreAffinitySet(kbdHandle, 1 << 1);
  vTaskCoreAffinitySet(logHandle, 1 << 0);

  // loop forever
  vTaskStartScheduler();
}

void loop() {}