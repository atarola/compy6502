#pragma once

#include <stdint.h> 

void terminalInit();
void terminalReceiveChar(uint8_t *ch);
void terminalTask(void *parameter);