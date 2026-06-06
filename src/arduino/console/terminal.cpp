#include <Arduino.h>
#include <queue.h>
#include <string.h>

#include "eve.h"
#include "terminal.h"
#include "display.h"
#include "logging.h"

#define TERM_COLS 58
#define TERM_ROWS 17

#define CLAMP(v, lo, hi) ((v) < (lo) ? (lo) : (v) > (hi) ? (hi) \
                                                         : (v))

const uint8_t ansi_to_textvga[] = {
  0x00,  // 0  - black
  0x04,  // 1  - red
  0x02,  // 2  - green
  0x06,  // 3  - yellow
  0x01,  // 4  - blue
  0x05,  // 5  - magenta
  0x03,  // 6  - cyan
  0x07,  // 7  - white
  0x08,  // 8  - bright black (dark grey)
  0x0C,  // 9  - bright red
  0x0A,  // 10 - bright green
  0x0E,  // 11 - bright yellow
  0x09,  // 12 - bright blue
  0x0D,  // 13 - bright magenta
  0x0B,  // 14 - bright cyan
  0x0F,  // 15 - bright white
};

typedef enum {
  STATE_NORMAL,
  STATE_ESC,
  STATE_ANSI,
} TermState;

uint8_t screen[TERM_ROWS][TERM_COLS][2];

QueueHandle_t terminalQueue = nullptr;

static int cursor_row;
static int cursor_col;
static uint8_t cursor_fg;
static uint8_t cursor_bg;
static bool cursor_visible;
static uint8_t cursor_under_ch;
static uint8_t cursor_under_attr;
static TickType_t cursor_blink_ticks;
static TermState state;
static char cmd_buf[32];
static int cmd_len;
static void (*commands[128])(int *, int) = { 0 };

static void cmdCursorDown(int *params, int count);
static void cmdCursorLeft(int *params, int count);
static void cmdCursorPos(int *params, int count);
static void cmdCursorRight(int *params, int count);
static void cmdCursorUp(int *params, int count);
static void cmdDispatch(char cmd);
static void cmdEraseLine(int *params, int count);
static void cmdEraseScreen(int *params, int count);
static void cmdHideCursor(int *params, int count);
static void cmdSgr(int *params, int count);
static void cmdShowCursor(int *params, int count);
static void onStateAnsi(uint8_t *ch);
static void onStateEsc(uint8_t *ch);
static void onStateNormal(uint8_t *ch);
static void resetCmdBuffer();
static void terminalClear();
static void terminalPutc(int row, int col, char ch, uint8_t attr);
static void terminalPutCharacter(uint8_t *ch);
static void terminalRender();
static void terminalRowClear();
static void terminalWriteToEve();

// --- init ---

void terminalInit() {
  cursor_row = 0;
  cursor_col = 0;
  cursor_fg = 0x0A;
  cursor_bg = 0x00;
  cursor_visible = true;
  cursor_blink_ticks = xTaskGetTickCount();
  state = STATE_NORMAL;
  cmd_len = 0;

  commands['H'] = cmdCursorPos;
  commands['f'] = cmdCursorPos;
  commands['A'] = cmdCursorUp;
  commands['B'] = cmdCursorDown;
  commands['C'] = cmdCursorRight;
  commands['D'] = cmdCursorLeft;
  commands['J'] = cmdEraseScreen;
  commands['K'] = cmdEraseLine;
  commands['m'] = cmdSgr;
  commands['h'] = cmdShowCursor;
  commands['l'] = cmdHideCursor;

  terminalClear();
  terminalQueue = xQueueCreate(16, sizeof(uint8_t));
}

void terminalTask(void *parameter) {
  uint8_t ch;

  for (;;) {
    if (xQueueReceive(terminalQueue, &ch, pdMS_TO_TICKS(250)) == pdTRUE) {
      switch (state) {
        case STATE_NORMAL:
          onStateNormal(&ch);
          break;
        case STATE_ESC:
          onStateEsc(&ch);
          break;
        case STATE_ANSI:
          onStateAnsi(&ch);
          break;
        default:
          state = STATE_NORMAL;
          break;
      }
    }

    if (xTaskGetTickCount() - cursor_blink_ticks >= pdMS_TO_TICKS(500)) {
      cursor_blink_ticks = xTaskGetTickCount();
      cursor_visible = !cursor_visible;
      terminalWriteToEve();
      terminalRender();
    }
  }
}

void terminalReceiveChar(uint8_t *ch) {
  if (terminalQueue == nullptr) {
    return;
  }

  xQueueSend(terminalQueue, ch, 0);
}

// --- state machine ---

static void onStateNormal(uint8_t *ch) {
  if (*ch == 0x1B) {
    state = STATE_ESC;
    return;
  }

  if (*ch == '\n' || *ch == '\r') {
    cursor_col = 0;
    cursor_row++;
    if (cursor_row >= TERM_ROWS) {
      cursor_row = TERM_ROWS - 1;
      memmove(screen[0], screen[1], sizeof(screen) - sizeof(screen[0]));
      terminalRowClear();
    }
    terminalWriteToEve();
    terminalRender();
    return;
  }

  if (*ch == '\b') {
    if (cursor_col > 0) {
      cursor_col--;
      terminalPutc(cursor_row, cursor_col, ' ', (cursor_bg << 4) | cursor_fg);
      terminalWriteToEve();
      terminalRender();
    }
    return;
  }

  terminalPutCharacter(ch);
}

static void onStateEsc(uint8_t *ch) {
  if (*ch == 0x5B) {
    cmd_len = 0;
    memset(cmd_buf, 0, sizeof(cmd_buf));
    state = STATE_ANSI;
  } else {
    state = STATE_NORMAL;
  }
}

static void onStateAnsi(uint8_t *ch) {
  if (cmd_len >= sizeof(cmd_buf) - 1) {
    resetCmdBuffer();
    state = STATE_NORMAL;
    return;
  }

  if (*ch >= 0x40) {
    cmdDispatch(*ch);
    resetCmdBuffer();
    state = STATE_NORMAL;
    return;
  }

  cmd_buf[cmd_len] = *ch;
  cmd_len++;
}

static void resetCmdBuffer() {
  cmd_len = 0;
  memset(cmd_buf, 0, sizeof(cmd_buf));
}

// --- screen ---

static void terminalClear() {
  for (int r = 0; r < TERM_ROWS; r++) {
    for (int c = 0; c < TERM_COLS; c++) {
      screen[r][c][0] = ' ';
      screen[r][c][1] = 0x0A;
    }
  }
}

static void terminalRowClear() {
  for (int c = 0; c < TERM_COLS; c++) {
    screen[cursor_row][c][0] = ' ';
    screen[cursor_row][c][1] = (cursor_bg << 4) | cursor_fg;
  }
}

static void terminalPutc(int row, int col, char ch, uint8_t attr) {
  if (row < 0 || row >= TERM_ROWS || col < 0 || col >= TERM_COLS) return;
  screen[row][col][0] = ch;
  screen[row][col][1] = attr;
}

static void terminalRender() {
  int i = 0;
  displayWrite32(EVE_RAM_DL + (i++ * 4), DL_CLEAR_RGB | 0x000000);
  displayWrite32(EVE_RAM_DL + (i++ * 4), DL_CLEAR | CLR_COL | CLR_STN | CLR_TAG);
  displayWrite32(EVE_RAM_DL + (i++ * 4), BITMAP_SOURCE(EVE_RAM_G));
  displayWrite32(EVE_RAM_DL + (i++ * 4), BITMAP_HANDLE(15));
  displayWrite32(EVE_RAM_DL + (i++ * 4), BITMAP_LAYOUT(EVE_TEXTVGA, TERM_COLS * 2, TERM_ROWS));
  displayWrite32(EVE_RAM_DL + (i++ * 4), BITMAP_SIZE(EVE_NEAREST, EVE_BORDER, EVE_BORDER, TERM_COLS * 8, TERM_ROWS * 16));
  displayWrite32(EVE_RAM_DL + (i++ * 4), BLEND_FUNC(EVE_ONE, EVE_ZERO));
  displayWrite32(EVE_RAM_DL + (i++ * 4), BEGIN(EVE_BITMAPS));
  displayWrite32(EVE_RAM_DL + (i++ * 4), VERTEX2F(8 * 16, 0));
  displayWrite32(EVE_RAM_DL + (i++ * 4), END());
  displayWrite32(EVE_RAM_DL + (i++ * 4), DL_DISPLAY);
  displayWrite32(REG_DLSWAP, EVE_DLSWAP_FRAME);
}

void terminalWriteToEve() {
  if (cursor_visible) {
    cursor_under_ch   = screen[cursor_row][cursor_col][0];
    cursor_under_attr = screen[cursor_row][cursor_col][1];
    screen[cursor_row][cursor_col][0] = 0xDB;
    screen[cursor_row][cursor_col][1] = (cursor_bg << 4) | cursor_fg;
  }

  uint8_t buf[TERM_ROWS * TERM_COLS * 2];
  int i = 0;
  for (int r = 0; r < TERM_ROWS; r++)
    for (int c = 0; c < TERM_COLS; c++) {
      buf[i++] = screen[r][c][0];
      buf[i++] = screen[r][c][1];
    }

  displayWrite(EVE_RAM_G, buf, sizeof(buf));

  if (cursor_visible) {
    screen[cursor_row][cursor_col][0] = cursor_under_ch;
    screen[cursor_row][cursor_col][1] = cursor_under_attr;
  }
}

static void terminalPutCharacter(uint8_t *ch) {
  terminalPutc(cursor_row, cursor_col, *ch, (cursor_bg << 4) | cursor_fg);

  cursor_col++;

  if (cursor_col == TERM_COLS) {
    cursor_col = 0;
    if (cursor_row >= TERM_ROWS - 1) {
      cursor_row = TERM_ROWS - 1;
      memmove(screen[0], screen[1], sizeof(screen) - sizeof(screen[0]));
      terminalRowClear();
    } else {
      cursor_row++;
    }
  }

  terminalWriteToEve();
  terminalRender();
}

// --- commands ---

static void cmdDispatch(char cmd) {
  int params[8] = { 0 };
  int count = 0;
  char *tok = strtok(cmd_buf, ";");

  while (tok && count < 8) {
    params[count++] = atoi(tok);
    tok = strtok(NULL, ";");
  }

  if (cmd < 128 && commands[cmd]) {
    commands[cmd](params, count);
  }
}

// ESC [ H - cursor home (1,1)
// ESC [ 5 ; 10 H - cursor to row 5, col 10
static void cmdCursorPos(int *params, int count) {
  int row_new = (count >= 1) ? params[0] : 1;
  cursor_row = CLAMP(row_new - 1, 0, TERM_ROWS - 1);

  int col_new = (count >= 2) ? params[1] : 1;
  cursor_col = CLAMP(col_new - 1, 0, TERM_COLS - 1);
}

// ESC [ A - cursor up 1
// ESC [ 3 A - cursor up 3
static void cmdCursorUp(int *params, int count) {
  int offset = (count > 0) ? params[0] : 1;
  cursor_row = CLAMP(cursor_row - offset, 0, TERM_ROWS - 1);
}

// ESC [ B - cursor down 1
// ESC [ 3 B - cursor down 3
static void cmdCursorDown(int *params, int count) {
  int offset = (count > 0) ? params[0] : 1;
  cursor_row = CLAMP(cursor_row + offset, 0, TERM_ROWS - 1);
}

// ESC [ C - cursor right 1
// ESC [ 3 C - cursor right 3
static void cmdCursorRight(int *params, int count) {
  int offset = (count > 0) ? params[0] : 1;
  cursor_col = CLAMP(cursor_col + offset, 0, TERM_COLS - 1);
}

// ESC [ D - cursor left 1
// ESC [ 3 D - cursor left 3
static void cmdCursorLeft(int *params, int count) {
  int offset = (count > 0) ? params[0] : 1;
  cursor_col = CLAMP(cursor_col - offset, 0, TERM_COLS - 1);
}

// ESC [ J - erase entire screen
static void cmdEraseScreen(int *params, int count) {
  terminalClear();
  terminalWriteToEve();
  terminalRender();
}

// ESC [ K - erase line from cursor
// ESC [ 2 K - erase entire line
static void cmdEraseLine(int *params, int count) {
  terminalRowClear();
  terminalWriteToEve();
  terminalRender();
}

// ESC [ 0 m       - reset colors
// ESC [ 31 m      - fg red
// ESC [ 42 m      - bg green
// ESC [ 1 ; 33 m  - fg yellow (bold ignored)
static void cmdSgr(int *params, int count) {
  if (count == 0) {
    cursor_fg = 0x0F;
    cursor_bg = 0x00;
    return;
  }

  for (int i = 0; i < count; i++) {
    int p = params[i];
    if (p == 0) {
      cursor_fg = 0x0F;
      cursor_bg = 0x00;
    } else if (p >= 30 && p <= 37) {
      cursor_fg = ansi_to_textvga[p - 30];
    } else if (p >= 40 && p <= 47) {
      cursor_bg = ansi_to_textvga[p - 40];
    } else if (p >= 90 && p <= 97) {
      cursor_fg = ansi_to_textvga[p - 90 + 8];
    } else if (p >= 100 && p <= 107) {
      cursor_bg = ansi_to_textvga[p - 100 + 8];
    }
  }
}

// ESC [ ? 25 l - hide cursor
static void cmdHideCursor(int *params, int count) {
  cursor_visible = 0;
}

// ESC [ ? 25 h - show cursor
static void cmdShowCursor(int *params, int count) {
  cursor_visible = 1;
}