use crate::display::DisplayHandle;
use crate::modes::DisplayMode;

pub struct Tui {
    dirty: bool,
}

impl Tui {
    pub fn new() -> Tui {
        Tui { dirty: true }
    }
}

impl DisplayMode for Tui {
    fn reset(&mut self) {
        self.dirty = true;
    }

    fn consume_txn(&mut self, _bytes: &[u8]) {}

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
    display
        .write32(EVE_RAM_DL + i * 4, clear_color_rgb(0x10, 0x10, 0x18))
        .await;
    i += 1;
    display.write32(EVE_RAM_DL + i * 4, clear(1, 1, 1)).await;
    i += 1;
    display.write32(EVE_RAM_DL + i * 4, DL_DISPLAY).await;
    display.write8(REG_DLSWAP, EVE_DLSWAP_FRAME).await;
}
