#pragma once

struct KeyEvent {
  uint8_t keycode;
  uint8_t modifier;
  char ascii;
};

void kbdInit();
void kbdTask(void *parameter);
bool kbdHasData();
bool kbdNextByte(uint8_t *byte, TickType_t wait);