use embassy_executor::Spawner;
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::{Channel, Sender};

use crate::display::EveDriver;

static TERMINAL_CHANNEL: Channel<CriticalSectionRawMutex, TextCmd, 32> = Channel::new();

type TerminalSender = Sender<'static, CriticalSectionRawMutex, TextCmd, 32>;

pub enum TextCmd {
    SetGraphics,
    PutChar(u8),
    SetCursor(u8, u8),
}

pub struct TextHandle(TerminalSender);
struct TextState;

impl TextHandle {
    pub async fn put_char(&self, c: u8) { todo!() }
    pub async fn set_cursor(&self, col: u8, row: u8) { todo!() }
    pub async fn new(spawner: &Spawner, driver: EveDriver) -> TextHandle { todo!() }
}

impl TextState {
    fn handle(&mut self, cmd: TextCmd) { todo!() }
    async fn render(&self, driver: &mut EveDriver) { todo!() }
}

#[embassy_executor::task]
async fn text_task(mut driver: EveDriver) { todo!() }
