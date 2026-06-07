use crate::display::DisplayHandle;

pub struct GraphicsHandle;

impl GraphicsHandle {
    pub fn new() -> GraphicsHandle {
        GraphicsHandle
    }
}

pub struct GraphicsState;

impl GraphicsState {
    pub async fn render(&self, driver: &mut DisplayHandle) {
        todo!()
    }
}

pub async fn graphics_init() -> GraphicsHandle {
    todo!()
}
