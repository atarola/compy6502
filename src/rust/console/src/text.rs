use embassy_executor::Spawner;
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::Channel;

use crate::display::DisplayDriver;

static TEXT_CHANNEL: Channel<CriticalSectionRawMutex, TextCmd, 32> = Channel::new();

pub enum TextCmd {
    PutChar(u8),
    SetCursor(u8, u8),
}

pub struct TextHandle;
struct TextState;

impl TextHandle {
    pub fn new() -> TextHandle { TextHandle }
    pub async fn put_char(&self, c: u8) { todo!() }
    pub async fn set_cursor(&self, col: u8, row: u8) { todo!() }
}

pub async fn text_init(spawner: &Spawner, driver: DisplayDriver) -> TextHandle { todo!() }

impl TextState {
    fn handle(&mut self, cmd: TextCmd) { todo!() }
    async fn render(&self, driver: &mut DisplayDriver) { todo!() }
}

#[embassy_executor::task]
async fn text_task(mut driver: DisplayDriver) { todo!() }
