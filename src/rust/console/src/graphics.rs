use crate::display::EveDriver;

pub struct GraphicsHandle;
pub struct GraphicsState;

impl GraphicsHandle {
}

impl GraphicsState {
    pub async fn new() -> GraphicsHandle { todo!() }
    pub async fn render(&self, driver: &mut EveDriver) { todo!() }
}
