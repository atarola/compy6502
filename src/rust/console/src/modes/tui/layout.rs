use super::KIND_VPANEL;
use super::node::{NO_NODE, NodeTable, PROP_FLEX, PROP_VISIBLE};

pub struct LayoutRect {
    pub handle: u8,
    pub x: u16,
    pub y: u16,
    pub w: u16,
    pub h: u16,
}

pub fn build(table: &NodeTable, w: u16, h: u16, rects: &mut heapless::Vec<LayoutRect, 64>) {
    layout_tree(table, 0, 0, 0, w, h, rects);
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

    let is_vertical = node.kind == KIND_VPANEL;
    let mut child = node.first_child;
    let mut offset = 0u16;
    let mut used_flex = 0u16;
    let mut first = true;

    while child != NO_NODE {
        let child_node = table.node(child);
        let flex = child_node.props[PROP_FLEX as usize] as u16;
        if flex == 0 {
            child = child_node.next_sibling;
            continue;
        }

        if is_vertical {
            let child_y = if first { y + offset } else { y + offset + 2 };
            let gap = child_y - y;
            let child_h = if used_flex + flex == total_flex {
                h.saturating_sub(gap)
            } else {
                (h as u32 * flex as u32 / total_flex as u32) as u16 - 1
            };
            layout_tree(table, child, x, child_y, w - 1, child_h, rects);
            offset += child_h + 1;
        } else {
            let child_x = if first { x + offset } else { x + offset + 2 };
            let gap = child_x - x;
            let child_w = if used_flex + flex == total_flex {
                w.saturating_sub(gap)
            } else {
                (w as u32 * flex as u32 / total_flex as u32) as u16 - 1
            };
            layout_tree(table, child, child_x, y, child_w, h - 1, rects);
            offset += child_w + 1;
        }
        used_flex += flex;
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
