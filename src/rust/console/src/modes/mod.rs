use crate::display::DisplayHandle;

pub mod manager;
pub mod text;
pub mod tui;

pub trait DisplayMode {
    fn reset(&mut self);
    fn consume(&mut self, byte: u8);
    fn tick(&mut self);
    async fn render(&mut self, display: &mut DisplayHandle);
}

pub use manager::modes_init;
