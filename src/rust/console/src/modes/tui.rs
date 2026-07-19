use crate::display::DisplayHandle;
use crate::modes::DisplayMode;

mod node;

use node::NodeTable;
use node::{NO_NODE, PROP_FLEX, PROP_VISIBLE};

const CMD_REVERT: u8 = 0x1E;
const CMD_COMMIT: u8 = 0x1F;
const CMD_DESTROY: u8 = 0x11;
const CMD_CREATE: u8 = 0x10;
const CMD_SET: u8 = 0x12;

const KIND_ROOT: u8 = 0x00;
const KIND_PANEL: u8 = 0x01;
const KIND_HPANEL: u8 = 0x02;
const KIND_VPANEL: u8 = 0x03;
const KIND_LABEL: u8 = 0x04;
const KIND_ITEM: u8 = 0x05;
const KIND_LISTBOX: u8 = 0x06;

const SCREEN_W: u16 = 480;
const SCREEN_H: u16 = 272;

const PANEL_BG: [u8; 3] = [40, 40, 50];

struct LayoutRect {
    handle: u8,
    x: u16,
    y: u16,
    w: u16,
    h: u16,
}

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
        layout_tree(&self.live, 0, 0, 0, SCREEN_W, SCREEN_H, &mut self.rects);
        log::info!("tui: render rects={}", self.rects.len());
        for r in self.rects.iter() {
            log::info!("tui: rect h=0x{:02X} x={} y={} w={} h={}", r.handle, r.x, r.y, r.w, r.h);
        }
        render_eve(display, &self.live, &self.rects).await;
        self.dirty = false;
    }
}

fn layout_tree(
    table: &NodeTable,
    handle: u8,
    x: u16,
    y: u16,
    w: u16,
    h: u16,
    rects: &mut heapless::Vec<LayoutRect, 64>,
) {
    let node = table.node(handle);

    if handle != 0 && node.props[PROP_VISIBLE as usize] == 0 {
        return;
    }

    if handle != 0 {
        let _ = rects.push(LayoutRect { handle, x, y, w, h });
    }

    let total_flex = count_flex(table, handle);
    if total_flex == 0 {
        return;
    }

    let mut child = node.first_child;
    let mut offset = 0u16;
    let mut first = true;

    while child != NO_NODE {
        let child_node = table.node(child);
        let flex = child_node.props[PROP_FLEX as usize] as u16;
        if flex == 0 {
            child = child_node.next_sibling;
            continue;
        }

        let child_w = (w as u32 * flex as u32 / total_flex as u32) as u16 - 1;
        let child_x = if first { x + offset } else { x + offset + 2 };
        layout_tree(table, child, child_x, y, child_w, h - 1, rects);
        offset += child_w + 1;
        first = false;
        child = child_node.next_sibling;
    }
}

fn count_flex(table: &NodeTable, handle: u8) -> u16 {
    let node = table.node(handle);
    let mut total = 0u16;
    let mut child = node.first_child;
    while child != NO_NODE {
        let child_node = table.node(child);
        if child_node.props[PROP_VISIBLE as usize] != 0 {
            total += child_node.props[PROP_FLEX as usize] as u16;
        }
        child = child_node.next_sibling;
    }
    total
}

async fn render_eve(display: &mut DisplayHandle, table: &NodeTable, rects: &[LayoutRect]) {
    use crate::eve::*;

    let mut i = 0u32;

    display.write32(EVE_RAM_DL + i * 4, clear_color_rgb(10, 10, 15)).await;
    i += 1;
    display.write32(EVE_RAM_DL + i * 4, clear(1, 1, 1)).await;
    i += 1;

    for rect in rects.iter() {
        let node = table.node(rect.handle);
        let color = match node.kind {
            KIND_PANEL | KIND_HPANEL | KIND_VPANEL => PANEL_BG,
            KIND_LISTBOX => [30, 30, 40],
            KIND_LABEL | KIND_ITEM => [50, 50, 60],
            _ => [40, 40, 50],
        };

        display.write32(EVE_RAM_DL + i * 4, color_rgb(color[0] as u32, color[1] as u32, color[2] as u32)).await;
        i += 1;
        display.write32(EVE_RAM_DL + i * 4, begin(EVE_RECTS)).await;
        i += 1;
        display.write32(EVE_RAM_DL + i * 4, vertex2f(rect.x as u32 * 16, rect.y as u32 * 16)).await;
        i += 1;
        display.write32(EVE_RAM_DL + i * 4, vertex2f(
            (rect.x + rect.w) as u32 * 16,
            (rect.y + rect.h) as u32 * 16,
        )).await;
        i += 1;
        display.write32(EVE_RAM_DL + i * 4, end()).await;
        i += 1;
    }

    display.write32(EVE_RAM_DL + i * 4, DL_DISPLAY).await;
    display.write8(REG_DLSWAP, EVE_DLSWAP_FRAME).await;
}
