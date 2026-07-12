use crate::modes::{CommandBuffer, DisplayMode};

pub struct Sprite;

impl Sprite {
    pub fn new() -> Sprite {
        Sprite
    }
}

impl DisplayMode for Sprite {
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
