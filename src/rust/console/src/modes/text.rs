use crate::modes::{CommandBuffer, DisplayMode};
use crate::display::DisplayHandle;

pub struct Text;

impl Text {
    pub fn new() -> Text {
        Text
    }
}

impl DisplayMode for Text {
    fn reset(&mut self) {
        log::info!("text reset");
    }

    fn start_txn(&mut self, _buf: &mut CommandBuffer) {
        log::info!("text start_txn");
    }

    fn consume(&mut self, _buf: &mut CommandBuffer, _byte: u8) {
        log::info!("text consume 0x{:02X}", _byte);
    }

    fn end_txn(&mut self, _buf: &mut CommandBuffer) {
        log::info!("text end_txn");
    }

    fn tick(&mut self) {}

    async fn render(&mut self, _display: &mut DisplayHandle) {}
}
