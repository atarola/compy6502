use crate::modes::{CommandBuffer, DisplayMode};
use crate::display::DisplayHandle;

const CMD_PUT_CHAR: u8 = 0x21;

pub struct Text {
    awaiting_put_char: bool,
}

impl Text {
    pub fn new() -> Text {
        Text {
            awaiting_put_char: false,
        }
    }
}

impl DisplayMode for Text {
    fn reset(&mut self) {
        self.awaiting_put_char = false;
        log::info!("text reset");
    }

    fn start_txn(&mut self, _buf: &mut CommandBuffer) {
        log::info!("text start_txn");
    }

    fn consume(&mut self, _buf: &mut CommandBuffer, _byte: u8) {
        log::info!("text consume 0x{:02X}", _byte);

        if self.awaiting_put_char {
            self.awaiting_put_char = false;
            log::info!("text put 0x{:02X}", _byte);
            return;
        }

        if _byte == CMD_PUT_CHAR {
            self.awaiting_put_char = true;
        }
    }

    fn end_txn(&mut self, _buf: &mut CommandBuffer) {
        log::info!("text end_txn");
    }

    fn tick(&mut self) {}

    async fn render(&mut self, _display: &mut DisplayHandle) {}
}
