use heapless::Vec;

use crate::display::DisplayHandle;

pub mod manager;
pub mod text;

pub struct CommandBuffer {
    pub buf: Vec<u8, 256>,
    pub len: u8,
}

impl CommandBuffer {
    pub fn new() -> CommandBuffer {
        CommandBuffer {
            buf: Vec::new(),
            len: 0,
        }
    }

    pub fn clear(&mut self) {
        self.buf.clear();
        self.len = 0;
    }
}

pub trait DisplayMode {
    fn reset(&mut self);
    fn start_txn(&mut self, buf: &mut CommandBuffer);
    fn consume(&mut self, buf: &mut CommandBuffer, byte: u8);
    fn end_txn(&mut self, buf: &mut CommandBuffer);
    fn tick(&mut self);
    async fn render(&mut self, display: &mut DisplayHandle);
}

pub use manager::{ModeHandle, modes_init};
