use heapless::Vec;

use self::AnsiCmd::{Backspace, Newline, PutChar};
use self::AnsiState::{Escape, Normal, Sequence};
use crate::display::DisplayHandle;
use crate::modes::DisplayMode;

const CMD_PUT_CHAR: u8 = 0x21;
const COLS: usize = 58;
const ROWS: usize = 17;

// ANSI color index to TEXTVGA palette index.
const ANSI_TO_TEXTVGA: [u8; 16] = [
    0x00, 0x04, 0x02, 0x06, 0x01, 0x05, 0x03, 0x07, 0x08, 0x0C, 0x0A, 0x0E, 0x09, 0x0D, 0x0B, 0x0F,
];

#[derive(Clone, Copy)]
struct Cell {
    ch: u8,
    attr: u8,
}

enum AnsiState {
    Normal,
    Escape,
    Sequence(Vec<u8, 16>),
}

enum AnsiCmd {
    PutChar(u8),
    Newline,
    Backspace,
    CursorPos(u8, u8),
    CursorUp(u8),
    CursorDown(u8),
    CursorRight(u8),
    CursorLeft(u8),
    EraseScreen,
    EraseLine,
    EraseLineFull,
    Sgr(heapless::Vec<u8, 8>),
    ShowCursor,
    HideCursor,
}

struct AnsiParser {
    state: AnsiState,
}

impl AnsiParser {
    fn new() -> AnsiParser {
        AnsiParser { state: Normal }
    }

    fn feed(&mut self, c: u8) -> Option<AnsiCmd> {
        match self.state {
            Normal => self.on_normal(c),
            Escape => self.on_esc(c),
            Sequence(_) => self.on_sequence(c),
        }
    }

    fn on_normal(&mut self, c: u8) -> Option<AnsiCmd> {
        match c {
            0x1B => {
                self.state = Escape;
                None
            }
            0x0D | 0x0A => Some(Newline),
            0x08 | 0x7F => Some(Backspace),
            _ => Some(PutChar(c)),
        }
    }

    fn on_esc(&mut self, c: u8) -> Option<AnsiCmd> {
        if c == 0x5B {
            self.state = Sequence(Vec::new());
            return None;
        }

        self.state = Normal;
        None
    }

    fn on_sequence(&mut self, c: u8) -> Option<AnsiCmd> {
        if c >= 0x40 {
            let old = core::mem::replace(&mut self.state, Normal);
            let Sequence(buf) = old else {
                return None;
            };
            return Self::dispatch(c, &buf);
        }

        let Sequence(ref mut buf) = self.state else {
            return None;
        };

        if buf.is_full() {
            self.state = Normal;
            return None;
        }

        let _ = buf.push(c);
        None
    }

    fn dispatch(cmd: u8, buf: &[u8]) -> Option<AnsiCmd> {
        let is_private = buf.first() == Some(&b'?');
        let (params, count) = Self::parse_params(if is_private { &buf[1..] } else { buf });

        match cmd {
            b'H' | b'f' => Some(AnsiCmd::CursorPos(
                params[0].saturating_sub(1),
                if count >= 2 {
                    params[1].saturating_sub(1)
                } else {
                    0
                },
            )),
            b'A' => Some(AnsiCmd::CursorUp(if params[0] == 0 {
                1
            } else {
                params[0]
            })),
            b'B' => Some(AnsiCmd::CursorDown(if params[0] == 0 {
                1
            } else {
                params[0]
            })),
            b'C' => Some(AnsiCmd::CursorRight(if params[0] == 0 {
                1
            } else {
                params[0]
            })),
            b'D' => Some(AnsiCmd::CursorLeft(if params[0] == 0 {
                1
            } else {
                params[0]
            })),
            b'J' => Some(AnsiCmd::EraseScreen),
            b'K' => Some(if params[0] == 2 {
                AnsiCmd::EraseLineFull
            } else {
                AnsiCmd::EraseLine
            }),
            b'm' => {
                let mut sgr = heapless::Vec::new();
                for param in params.iter().take(count) {
                    let _ = sgr.push(*param);
                }
                Some(AnsiCmd::Sgr(sgr))
            }
            b'h' if is_private => Some(AnsiCmd::ShowCursor),
            b'l' if is_private => Some(AnsiCmd::HideCursor),
            _ => None,
        }
    }

    fn parse_params(buf: &[u8]) -> ([u8; 8], usize) {
        let mut params = [0u8; 8];
        let mut count = 0usize;
        let mut val = 0u8;

        for &b in buf {
            if b == b';' {
                if count < 8 {
                    params[count] = val;
                    count += 1;
                }
                val = 0;
            } else if b >= b'0' && b <= b'9' {
                val = val.saturating_mul(10).saturating_add(b - b'0');
            }
        }

        if count < 8 {
            params[count] = val;
            count += 1;
        }

        (params, count)
    }
}

struct TextState {
    grid: [[Cell; COLS]; ROWS],
    cursor_x: u8,
    cursor_y: u8,
    attr: u8,
    cursor_visible: bool,
    dirty: bool,
}

impl TextState {
    fn new() -> TextState {
        TextState {
            grid: [[Cell {
                ch: b' ',
                attr: 0x0A,
            }; COLS]; ROWS],
            cursor_x: 0,
            cursor_y: 0,
            attr: 0x0A,
            cursor_visible: true,
            dirty: true,
        }
    }

    fn apply(&mut self, cmd: AnsiCmd) {
        match cmd {
            AnsiCmd::PutChar(c) => self.put_character(c),
            AnsiCmd::Newline => self.apply_newline(),
            AnsiCmd::Backspace => self.apply_backspace(),
            AnsiCmd::CursorPos(r, c) => self.apply_cursor_pos(r, c),
            AnsiCmd::CursorUp(n) => self.apply_cursor_up(n),
            AnsiCmd::CursorDown(n) => self.apply_cursor_down(n),
            AnsiCmd::CursorRight(n) => self.apply_cursor_right(n),
            AnsiCmd::CursorLeft(n) => self.apply_cursor_left(n),
            AnsiCmd::EraseScreen => self.clear(),
            AnsiCmd::EraseLine => self.row_clear(),
            AnsiCmd::EraseLineFull => self.row_clear(),
            AnsiCmd::Sgr(params) => self.apply_sgr(&params),
            AnsiCmd::ShowCursor => self.apply_show_cursor(true),
            AnsiCmd::HideCursor => self.apply_show_cursor(false),
        }
    }

    fn apply_newline(&mut self) {
        self.cursor_x = 0;
        self.cursor_y += 1;
        if self.cursor_y as usize >= ROWS {
            self.cursor_y = (ROWS - 1) as u8;
            self.scroll();
        }
        self.dirty = true;
    }

    fn apply_backspace(&mut self) {
        if self.cursor_x > 0 {
            self.cursor_x -= 1;
            let x = self.cursor_x as usize;
            let y = self.cursor_y as usize;
            self.grid[y][x] = Cell {
                ch: b' ',
                attr: self.attr,
            };
            self.dirty = true;
        }
    }

    fn apply_cursor_pos(&mut self, row: u8, col: u8) {
        self.cursor_y = row.min((ROWS - 1) as u8);
        self.cursor_x = col.min((COLS - 1) as u8);
        self.dirty = true;
    }

    fn apply_cursor_up(&mut self, n: u8) {
        self.cursor_y = self.cursor_y.saturating_sub(n);
        self.dirty = true;
    }

    fn apply_cursor_down(&mut self, n: u8) {
        self.cursor_y = (self.cursor_y + n).min((ROWS - 1) as u8);
        self.dirty = true;
    }

    fn apply_cursor_right(&mut self, n: u8) {
        self.cursor_x = (self.cursor_x + n).min((COLS - 1) as u8);
        self.dirty = true;
    }

    fn apply_cursor_left(&mut self, n: u8) {
        self.cursor_x = self.cursor_x.saturating_sub(n);
        self.dirty = true;
    }

    fn apply_sgr(&mut self, params: &[u8]) {
        if params.is_empty() {
            self.attr = 0x0F;
            self.dirty = true;
            return;
        }

        for &p in params {
            match p {
                0 => self.attr = 0x0F,
                30..=37 => self.attr = (self.attr & 0xF0) | ANSI_TO_TEXTVGA[(p - 30) as usize],
                40..=47 => {
                    self.attr = (self.attr & 0x0F) | (ANSI_TO_TEXTVGA[(p - 40) as usize] << 4)
                }
                90..=97 => self.attr = (self.attr & 0xF0) | ANSI_TO_TEXTVGA[(p - 90 + 8) as usize],
                100..=107 => {
                    self.attr = (self.attr & 0x0F) | (ANSI_TO_TEXTVGA[(p - 100 + 8) as usize] << 4)
                }
                _ => {}
            }
        }
        self.dirty = true;
    }

    fn apply_show_cursor(&mut self, visible: bool) {
        self.cursor_visible = visible;
        self.dirty = true;
    }

    fn blink(&mut self) {
        self.cursor_visible = !self.cursor_visible;
        self.dirty = true;
    }

    fn clear(&mut self) {
        for row in self.grid.iter_mut() {
            for cell in row.iter_mut() {
                *cell = Cell {
                    ch: b' ',
                    attr: self.attr,
                };
            }
        }
        self.cursor_x = 0;
        self.cursor_y = 0;
        self.dirty = true;
    }

    fn row_clear(&mut self) {
        let row = self.cursor_y as usize;
        for cell in self.grid[row].iter_mut() {
            *cell = Cell {
                ch: b' ',
                attr: self.attr,
            };
        }
        self.dirty = true;
    }

    fn scroll(&mut self) {
        self.grid.rotate_left(1);
        let last = ROWS - 1;
        for cell in self.grid[last].iter_mut() {
            *cell = Cell {
                ch: b' ',
                attr: self.attr,
            };
        }
        self.dirty = true;
    }

    fn put_character(&mut self, c: u8) {
        let x = self.cursor_x as usize;
        let y = self.cursor_y as usize;
        self.grid[y][x] = Cell {
            ch: c,
            attr: self.attr,
        };
        self.cursor_x += 1;
        if self.cursor_x as usize >= COLS {
            self.cursor_x = 0;
            self.cursor_y += 1;
            if self.cursor_y as usize >= ROWS {
                self.cursor_y = (ROWS - 1) as u8;
                self.scroll();
            }
        }
        self.dirty = true;
    }
}

pub struct Text {
    awaiting_put_char: bool,
    blink_ticks: u8,
    parser: AnsiParser,
    state: TextState,
}

impl Text {
    pub fn new() -> Text {
        Text {
            awaiting_put_char: false,
            blink_ticks: 0,
            parser: AnsiParser::new(),
            state: TextState::new(),
        }
    }

    fn put_char(&mut self, c: u8) {
        if let Some(cmd) = self.parser.feed(c) {
            self.state.apply(cmd);
        }
    }
}

impl DisplayMode for Text {
    fn reset(&mut self) {
        self.awaiting_put_char = false;
        self.blink_ticks = 0;
        self.parser = AnsiParser::new();
        self.state = TextState::new();
    }

    fn start_txn(&mut self) {}

    fn consume(&mut self, byte: u8) {
        if self.awaiting_put_char {
            self.awaiting_put_char = false;
            log::info!("text: put char 0x{:02X}", byte);
            self.put_char(byte);
            return;
        }

        if byte == CMD_PUT_CHAR {
            log::info!("text: put char opcode");
            self.awaiting_put_char = true;
        }
    }

    fn end_txn(&mut self) {}

    fn tick(&mut self) {
        self.blink_ticks += 1;
        if self.blink_ticks >= 31 {
            self.blink_ticks = 0;
            self.state.blink();
        }
    }

    async fn render(&mut self, display: &mut DisplayHandle) {
        if !self.state.dirty {
            return;
        }

        push_state(&self.state, display).await;
        render_display(display).await;
        self.state.dirty = false;
    }
}

async fn push_state(state: &TextState, driver: &mut DisplayHandle) {
    use crate::eve::EVE_RAM_G;

    driver.begin_bulk(EVE_RAM_G).await;
    for (r, row) in state.grid.iter().enumerate() {
        for (c, cell) in row.iter().enumerate() {
            let (ch, attr) = if state.cursor_visible
                && r == state.cursor_y as usize
                && c == state.cursor_x as usize
            {
                (0xDB, state.attr)
            } else {
                (cell.ch, cell.attr)
            };
            driver.bulk_byte(ch).await;
            driver.bulk_byte(attr).await;
        }
    }
    driver.end_bulk().await;
}

async fn render_display(driver: &mut DisplayHandle) {
    use crate::eve::*;

    let mut i = 0u32;
    driver.write32(EVE_RAM_DL + i * 4, DL_CLEAR_RGB).await;
    i += 1;
    driver.write32(EVE_RAM_DL + i * 4, clear(1, 1, 1)).await;
    i += 1;
    driver
        .write32(EVE_RAM_DL + i * 4, bitmap_source(EVE_RAM_G))
        .await;
    i += 1;
    driver.write32(EVE_RAM_DL + i * 4, bitmap_handle(15)).await;
    i += 1;
    driver
        .write32(
            EVE_RAM_DL + i * 4,
            bitmap_layout(EVE_TEXTVGA, (COLS * 2) as u32, ROWS as u32),
        )
        .await;
    i += 1;
    driver
        .write32(
            EVE_RAM_DL + i * 4,
            bitmap_size(
                EVE_NEAREST,
                EVE_BORDER,
                EVE_BORDER,
                (COLS * 8) as u32,
                (ROWS * 16) as u32,
            ),
        )
        .await;
    i += 1;
    driver
        .write32(EVE_RAM_DL + i * 4, blend_func(EVE_ONE, EVE_ZERO))
        .await;
    i += 1;
    driver.write32(EVE_RAM_DL + i * 4, begin(EVE_BITMAPS)).await;
    i += 1;
    driver
        .write32(EVE_RAM_DL + i * 4, vertex2f(8 * 16, 0))
        .await;
    i += 1;
    driver.write32(EVE_RAM_DL + i * 4, end()).await;
    i += 1;
    driver.write32(EVE_RAM_DL + i * 4, DL_DISPLAY).await;
    driver.write8(REG_DLSWAP, EVE_DLSWAP_FRAME).await;
}
