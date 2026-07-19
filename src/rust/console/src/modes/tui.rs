use crate::display::DisplayHandle;
use crate::modes::DisplayMode;

mod node;

use node::NodeTable;

const CMD_REVERT: u8 = 0x1E;
const CMD_COMMIT: u8 = 0x1F;

pub struct Tui {
    live: NodeTable,
    staged: NodeTable,
    dirty: bool,
}

impl Tui {
    pub fn new() -> Tui {
        Tui {
            live: NodeTable::new(),
            staged: NodeTable::new(),
            dirty: true,
        }
    }
}

impl DisplayMode for Tui {
    fn reset(&mut self) {
        self.dirty = true;
    }

    fn consume_txn(&mut self, bytes: &[u8]) {
        if bytes.len() != 1 {
            return;
        }

        match bytes[0] {
            CMD_REVERT => {
                log::info!("tui: revert");
                self.staged = self.live.clone();
                self.dirty = true;
            }
            CMD_COMMIT => {
                log::info!("tui: commit");
                core::mem::swap(&mut self.live, &mut self.staged);
                self.dirty = true;
            }
            _ => return,
        }
    }

    fn tick(&mut self) {}

    async fn render(&mut self, display: &mut DisplayHandle) {
        if !self.dirty {
            return;
        }

        render_log(display, &self.live).await;
        self.dirty = false;
    }
}

async fn render_log(_display: &mut DisplayHandle, live: &NodeTable) {
    let root = live.root();
    log::info!("tui: render");
    log::info!("tui: root kind=0x{:02X} state=0x{:02X}", root.kind, root.state);
}
