use crate::modes::{CommandBuffer, DisplayMode};

pub struct Tui;

impl Tui {
    pub fn new() -> Tui {
        Tui
    }
}

impl DisplayMode for Tui {
    fn reset(&mut self) {
        todo!()
    }

    fn start_txn(&mut self, _buf: &mut CommandBuffer) {
        todo!()
    }

    fn consume(&mut self, _buf: &mut CommandBuffer, _byte: u8) {
        todo!()
    }

    fn end_txn(&mut self, _buf: &mut CommandBuffer) {
        todo!()
    }
}
