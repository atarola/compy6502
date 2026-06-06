use crate::display::DisplayDriver;

pub struct GraphicsHandle;
pub struct GraphicsState;

impl GraphicsHandle {
    pub fn new() -> GraphicsHandle { GraphicsHandle }
}

pub async fn graphics_init() -> GraphicsHandle { todo!() }

impl GraphicsState {
    pub async fn render(&self, driver: &mut DisplayDriver) { todo!() }
}
