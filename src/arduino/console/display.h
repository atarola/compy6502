#pragma once

#include <stdint.h>
#include <stddef.h>

void displayInit();
void displayTask(void *parameter);

void displayCmd(uint8_t cmd);

void displayWrite(uint32_t addr, uint8_t *data, size_t len);
void displayRead(uint32_t addr, uint8_t *out, size_t len);

void displayWrite8(uint32_t addr, uint8_t data);
void displayWrite16(uint32_t addr, uint16_t data);
void displayWrite32(uint32_t addr, uint32_t data);

uint8_t displayRead8(uint32_t addr);
uint16_t displayRead16(uint32_t addr);
uint32_t displayRead32(uint32_t addr);