mod node;
mod parser;

use crate::display::DisplayHandle;
use crate::modes::tui::node::Tree;
use crate::modes::tui::parser::{Command, Parser};
use crate::modes::{CommandBuffer, DisplayMode};

pub struct Tui {
    parser: Parser,
    staged: Tree,
    committed: Tree,
    dirty: bool,
}

impl Tui {
    pub fn new() -> Tui {
        let tree = Tree::new();
        Tui {
            parser: Parser::new(),
            staged: tree,
            committed: tree,
            dirty: true,
        }
    }

    fn apply(&mut self, command: Command) {
        match command {
            Command::Create {
                handle,
                parent,
                kind,
            } => self.staged.create(handle, parent, kind),
            Command::Remove { handle } => self.staged.remove(handle),
            Command::SetProp { handle, key, value } => self.staged.set_prop(handle, key, value),
            Command::SetText { handle, len } => self.staged.set_text_len(handle, len),
            Command::Abort => {
                self.staged = self.committed;
                self.dirty = true;
            }
            Command::Commit => {
                self.committed = self.staged;
                self.dirty = true;
            }
        }
    }
}

impl DisplayMode for Tui {
    fn reset(&mut self) {
        self.parser = Parser::new();
        self.staged = Tree::new();
        self.committed = self.staged;
        self.dirty = true;
    }

    fn start_txn(&mut self, _buf: &mut CommandBuffer) {}

    fn consume(&mut self, _buf: &mut CommandBuffer, byte: u8) {
        if let Some(command) = self.parser.feed(byte) {
            self.apply(command);
        }
    }

    fn end_txn(&mut self, _buf: &mut CommandBuffer) {}

    fn tick(&mut self) {}

    async fn render(&mut self, display: &mut DisplayHandle) {
        if !self.dirty {
            return;
        }

        render_stub(display).await;
        self.dirty = false;
    }
}

async fn render_stub(display: &mut DisplayHandle) {
    use crate::eve::*;

    let mut i = 0u32;
    display.write32(EVE_RAM_DL + i * 4, 0x020000FF).await;
    i += 1;
    display.write32(EVE_RAM_DL + i * 4, clear(1, 1, 1)).await;
    i += 1;
    display.write32(EVE_RAM_DL + i * 4, DL_DISPLAY).await;
    display.write8(REG_DLSWAP, EVE_DLSWAP_FRAME).await;
}
