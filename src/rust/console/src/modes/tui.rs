use crate::display::DisplayHandle;
use crate::modes::DisplayMode;

mod node;

use node::NodeTable;
use node::NO_NODE;

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

        render_log(display, &self.live).await;
        self.dirty = false;
    }
}

async fn render_log(_display: &mut DisplayHandle, live: &NodeTable) {
    log::info!("tui: render");
    render_node(live, 0, 0);
}

fn render_node(table: &NodeTable, handle: u8, depth: usize) {
    const INDENT: [&str; 8] = ["", "  ", "    ", "      ", "        ", "          ", "            ", "              "];

    let node = table.node(handle);
    let indent = INDENT.get(depth).copied().unwrap_or("              ");
    log::info!("tui: {}- 0x{:02X} kind={}", indent, handle, kind_name(node.kind));

    if node.props[0] != 0 || node.props[1] != 0 || node.props[2] != 0 || node.props[3] != 0 {
        log::info!(
            "tui: {}  props x={} y={} w={} h={}",
            indent,
            node.props[0],
            node.props[1],
            node.props[2],
            node.props[3]
        );
    }

    let mut child = node.first_child;
    while child != NO_NODE {
        render_node(table, child, depth + 1);
        child = table.node(child).next_sibling;
    }
}

fn kind_name(kind: u8) -> &'static str {
    match kind {
        KIND_ROOT => "root",
        KIND_PANEL => "panel",
        KIND_HPANEL => "hpanel",
        KIND_VPANEL => "vpanel",
        KIND_LABEL => "label",
        KIND_ITEM => "item",
        KIND_LISTBOX => "listbox",
        _ => "unknown",
    }
}
