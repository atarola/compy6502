use heapless::Vec;

pub mod text;
pub mod tui;
pub mod sprite;
pub mod manager;

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
}

pub use manager::{modes_init, ModeEvent, ModeHandle, Modes};
