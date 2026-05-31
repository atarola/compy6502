#include <Arduino.h>
#include <FreeRTOS.h>
#include <task.h>
#include <queue.h>

#include "keyboard.h"
#include "usbh_helper.h"
#include "logging.h"

#define MAX_REPORT 4

QueueHandle_t kbdQueue = nullptr;
static uint8_t const keycode2ascii[128][2] = {HID_KEYCODE_TO_ASCII};

// Each HID instance can has multiple reports
static struct {
  uint8_t report_count;
  tuh_hid_report_info_t report_info[MAX_REPORT];
} hid_info[CFG_TUH_HID];

struct AnsiKey {
  uint8_t keycode;
  const char *sequence;
};

// mapping of HID keys to ansi keycodes
static const AnsiKey ansiKeys[] = {
  { HID_KEY_ARROW_UP,    "\x1B[A" },
  { HID_KEY_ARROW_DOWN,  "\x1B[B" },
  { HID_KEY_ARROW_RIGHT, "\x1B[C" },
  { HID_KEY_ARROW_LEFT,  "\x1B[D" },

  { HID_KEY_HOME,        "\x1B[H" },
  { HID_KEY_END,         "\x1B[F" },

  { HID_KEY_DELETE,      "\x1B[3~" },

  { HID_KEY_F1,          "\x1BOP" },
  { HID_KEY_F2,          "\x1BOQ" },
  { HID_KEY_F3,          "\x1BOR" },
  { HID_KEY_F4,          "\x1BOS" },
};

void kbdInit() {
  kbdQueue = xQueueCreate(16, sizeof(uint8_t));
}

void kbdTask(void *parameter) {
  rp2040_configure_pio_usb();
  USBHost.begin(1);

  for (;;) {
    USBHost.task();
    taskYIELD();
  }
}

bool kbdHasData() {
  return uxQueueMessagesWaiting(kbdQueue) == 0;
}

bool kbdNextByte(uint8_t *byte, TickType_t wait) {
  return xQueueReceive(kbdQueue, byte, wait) == pdTRUE;
}

static bool reportHasKey(hid_keyboard_report_t const *report, uint8_t keycode) {
  for (uint8_t index = 0; index < 6; index++) {
    if (report->keycode[index] == keycode) {
      return true;
    }
  }

  return false;
}

static bool reportHasShift(hid_keyboard_report_t const *report) {
  return report->modifier & (KEYBOARD_MODIFIER_LEFTSHIFT | KEYBOARD_MODIFIER_RIGHTSHIFT);
}

static void kbdSendByte(uint8_t byte) {
  xQueueSend(kbdQueue, &byte, 0);
}

static void kbdSendAnsi(const char *sequence) {
  while (*sequence) {
    kbdSendByte(*sequence++);
  }
}

static bool sendAnsiKey(uint8_t keycode) {
  for (const auto &entry : ansiKeys) {
    if (entry.keycode == keycode) {
      kbdSendAnsi(entry.sequence);
      return true;
    }
  }

  return false;
}

static void processKeyPress(hid_keyboard_report_t const *report, uint8_t keycode) {
  bool shifted = reportHasShift(report);
  uint8_t ascii = keycode2ascii[keycode][shifted ? 1 : 0];

  if (ascii != 0) {
    xQueueSend(kbdQueue, &ascii, 0);
    return;
  }

  sendAnsiKey(keycode);
}

static void processKbdReport(hid_keyboard_report_t const *report) {
  static hid_keyboard_report_t previousReport = {0, 0, {0}};

  if (kbdQueue == nullptr) {
    return;
  }

  for (uint8_t index = 0; index < 6; index++) {
    uint8_t keycode = report->keycode[index];

    bool wasAlreadyPressed = reportHasKey(&previousReport, keycode);
    if (!wasAlreadyPressed) {
      processKeyPress(report, keycode);
    }
  }

  previousReport = *report;
}

extern "C" {
  void tuh_hid_mount_cb(uint8_t dev_addr, uint8_t instance, uint8_t const *desc_report, uint16_t desc_len) {
    (void) desc_report;
    (void) desc_len;

    logMessage("HID device address = %d, instance = %d is mounted", dev_addr, instance);

    // Interface protocol (hid_interface_protocol_enum_t)
    const char *protocol_str[] = {"None", "Keyboard", "Mouse"};
    uint8_t const itf_protocol = tuh_hid_interface_protocol(dev_addr, instance);

    logMessage("HID Interface Protocol = %s", protocol_str[itf_protocol]);

    // By default, host stack will use boot protocol on supported interface.
    // Therefore for this simple example, we only need to parse generic report descriptor (with built-in parser)
    if (itf_protocol == HID_ITF_PROTOCOL_NONE) {
      hid_info[instance].report_count = tuh_hid_parse_report_descriptor(hid_info[instance].report_info, MAX_REPORT, desc_report, desc_len);
      logMessage("HID has %u reports", hid_info[instance].report_count);
    }

    // request to receive report
    // tuh_hid_report_received_cb() will be invoked when report is available
    if (!tuh_hid_receive_report(dev_addr, instance)) {
      logMessage("Error: cannot request to receive report");
    }
  }

  // Invoked when device with hid interface is un-mounted
  void tuh_hid_umount_cb(uint8_t dev_addr, uint8_t instance) {
    logMessage("HID device address = %d, instance = %d is unmounted", dev_addr, instance);
  }

  // Invoked when received report from device via interrupt endpoint
  void tuh_hid_report_received_cb(uint8_t dev_addr, uint8_t instance, uint8_t const *report, uint16_t len) {
    uint8_t const itf_protocol = tuh_hid_interface_protocol(dev_addr, instance);

    if (itf_protocol == HID_ITF_PROTOCOL_KEYBOARD) {
      processKbdReport((hid_keyboard_report_t const *) report);
    }

    // continue to request to receive report
    if (!tuh_hid_receive_report(dev_addr, instance)) {
      logMessage("Error: cannot request to receive report");
    }
  }
}
