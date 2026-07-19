use crate::display::DisplayHandle;
use crate::eve::*;

use super::layout::LayoutRect;
use super::node::NodeTable;
use super::{KIND_HPANEL, KIND_ITEM, KIND_LABEL, KIND_LISTBOX, KIND_PANEL, KIND_VPANEL};

const PANEL_BG: [u8; 3] = [1, 5, 9];
const PANEL_BORDER: [u8; 3] = [0, 58, 86];
const PANEL_INSET: [u8; 3] = [0, 12, 20];

struct Painter<'a> {
    display: &'a mut DisplayHandle,
    i: u32,
}

impl<'a> Painter<'a> {
    fn new(display: &'a mut DisplayHandle) -> Painter<'a> {
        Painter { display, i: 0 }
    }

    async fn write(&mut self, word: u32) {
        self.display.write32(EVE_RAM_DL + self.i * 4, word).await;
        self.i += 1;
    }

    async fn clear(&mut self, color: [u8; 3]) {
        self.write(clear_color_rgb(
            color[0] as u32,
            color[1] as u32,
            color[2] as u32,
        ))
        .await;
        self.write(clear(1, 1, 1)).await;
    }

    async fn pixel_mode(&mut self) {
        // TUI chrome should be pixel-sharp. The FT800 anti-aliases line
        // primitives, so this mode renders with opaque blending and uses
        // scissored clears for hard rectangle fills.
        self.write(blend_func(EVE_ONE, EVE_ZERO)).await;
    }

    async fn panel(&mut self, rect: &LayoutRect) {
        self.rect(rect.x, rect.y, rect.w, rect.h, PANEL_BG).await;

        if rect.w > 2 && rect.h > 2 {
            self.outline(rect.x, rect.y, rect.w, rect.h, PANEL_BORDER)
                .await;
        }

        if rect.w > 8 && rect.h > 8 {
            self.rect(rect.x + 2, rect.y + 2, rect.w - 4, 1, PANEL_INSET)
                .await;
            self.rect(rect.x + 2, rect.y + 2, 1, rect.h - 4, PANEL_INSET)
                .await;
        }
    }

    async fn outline(&mut self, x: u16, y: u16, w: u16, h: u16, color: [u8; 3]) {
        self.rect(x, y, w, 1, color).await;
        self.rect(x, y + h - 1, w, 1, color).await;
        self.rect(x, y, 1, h, color).await;
        self.rect(x + w - 1, y, 1, h, color).await;
    }

    async fn rect(&mut self, x: u16, y: u16, w: u16, h: u16, color: [u8; 3]) {
        // Avoid BEGIN(RECTS): FT800 rectangles are rounded and affected by
        // LINE_WIDTH. A color CLEAR clipped by SCISSOR_XY/SIZE gives a hard
        // pixel-aligned fill. SAVE/RESTORE keeps the temporary scissor local.
        self.write(save_context()).await;
        self.write(scissor_xy(x as u32, y as u32)).await;
        self.write(scissor_size(w as u32, h as u32)).await;
        self.write(clear_color_rgb(
            color[0] as u32,
            color[1] as u32,
            color[2] as u32,
        ))
        .await;
        self.write(clear(1, 0, 0)).await;
        self.write(restore_context()).await;
    }

    async fn raw_rect(&mut self, rect: &LayoutRect, color: [u8; 3]) {
        self.write(color_rgb(color[0] as u32, color[1] as u32, color[2] as u32))
            .await;
        self.write(begin(EVE_RECTS)).await;
        self.write(vertex2f(rect.x as u32 * 16, rect.y as u32 * 16))
            .await;
        self.write(vertex2f(
            (rect.x + rect.w) as u32 * 16,
            (rect.y + rect.h) as u32 * 16,
        ))
        .await;
        self.write(end()).await;
    }

    async fn finish(&mut self) {
        self.write(DL_DISPLAY).await;
        self.display.write8(REG_DLSWAP, EVE_DLSWAP_FRAME).await;
    }
}

pub async fn render(display: &mut DisplayHandle, table: &NodeTable, rects: &[LayoutRect]) {
    let mut painter = Painter::new(display);

    painter.clear([10, 10, 15]).await;
    painter.pixel_mode().await;

    for rect in rects.iter() {
        let node = table.node(rect.handle);
        let color = match node.kind {
            KIND_PANEL => {
                painter.panel(rect).await;
                continue;
            }
            KIND_HPANEL | KIND_VPANEL => continue,
            KIND_LISTBOX => [30, 30, 40],
            KIND_LABEL | KIND_ITEM => [50, 50, 60],
            _ => [40, 40, 50],
        };

        painter.raw_rect(rect, color).await;
    }

    painter.finish().await;
}
