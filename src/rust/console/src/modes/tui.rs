use crate::display::DisplayHandle;
use crate::modes::DisplayMode;

mod draw;
mod layout;
mod node;

use layout::LayoutRect;
use node::NodeTable;

const CMD_REVERT: u8 = 0x1E;
const CMD_COMMIT: u8 = 0x1F;
const CMD_DESTROY: u8 = 0x11;
const CMD_CREATE: u8 = 0x10;
const CMD_SET: u8 = 0x12;

const KIND_ROOT: u8 = 0x00;
pub(super) const KIND_PANEL: u8 = 0x01;
pub(super) const KIND_HPANEL: u8 = 0x02;
const KIND_VPANEL: u8 = 0x03;
pub(super) const KIND_LABEL: u8 = 0x04;
pub(super) const KIND_ITEM: u8 = 0x05;
pub(super) const KIND_LISTBOX: u8 = 0x06;

const SCREEN_W: u16 = 480;
const SCREEN_H: u16 = 272;

pub struct Tui {
    live: NodeTable,
    staged: NodeTable,
    dirty: bool,
    rects: heapless::Vec<LayoutRect, 64>,
}

impl Tui {
    pub fn new() -> Tui {
        Tui {
            live: NodeTable::new(),
            staged: NodeTable::new(),
            dirty: true,
            rects: heapless::Vec::new(),
        }
    }
}

impl DisplayMode for Tui {
    fn reset(&mut self) {
        self.dirty = true;
    }

    fn consume_txn(&mut self, bytes: &[u8]) {
        match bytes {
            [CMD_REVERT] => {
                log::info!("tui: revert");
                self.staged = self.live.clone();
                self.dirty = true;
            }
            [CMD_COMMIT] => {
                log::info!("tui: commit");
                self.live = self.staged.clone();
                self.dirty = true;
            }
            [CMD_DESTROY, handle] => {
                log::info!("tui: destroy handle=0x{:02X}", handle);
                self.staged.destroy(*handle);
                self.dirty = true;
            }
            [CMD_CREATE, kind, handle, parent] => {
                log::info!(
                    "tui: create kind=0x{:02X} handle=0x{:02X} parent=0x{:02X}",
                    kind,
                    handle,
                    parent
                );
                if self.staged.create(*kind, *handle, *parent) {
                    self.dirty = true;
                }
            }
            [CMD_SET, handle, key, value] => {
                log::info!(
                    "tui: set handle=0x{:02X} key=0x{:02X} value=0x{:02X}",
                    handle,
                    key,
                    value
                );
                self.staged.set_prop(*handle, *key, *value);
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

        self.rects.clear();
        layout::build(&self.live, SCREEN_W, SCREEN_H, &mut self.rects);
        log::info!("tui: render rects={}", self.rects.len());
        for r in self.rects.iter() {
            log::info!(
                "tui: rect h=0x{:02X} x={} y={} w={} h={}",
                r.handle,
                r.x,
                r.y,
                r.w,
                r.h
            );
        }
        draw::render(display, &self.live, &self.rects).await;
        self.dirty = false;
    }
}
