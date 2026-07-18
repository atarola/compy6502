use embassy_executor::Spawner;
use embassy_futures::select::{Either, select};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::Channel;
use embassy_time::{Duration, Ticker};

use crate::display::DisplayHandle;
use crate::modes::DisplayMode;
use crate::modes::text::Text;
use crate::modes::tui::Tui;

const SWITCH_MODE_OPCODE: u8 = 0xFF;
const MODE_TEXT: u8 = 0x00;
const MODE_TUI: u8 = 0x01;

#[derive(Clone, Copy)]
pub enum ModeEvent {
    StartTxn,
    Consume(u8),
    EndTxn,
    SwitchMode(u8),
}

static MODE_CHANNEL: Channel<CriticalSectionRawMutex, ModeEvent, 256> = Channel::new();

pub struct ModeHandle;

enum ActiveMode {
    Text,
    Tui,
}

enum ModeTxnState {
    AwaitOpcode,
    AwaitMode,
    Active,
}

impl ModeHandle {
    pub fn new() -> ModeHandle {
        ModeHandle
    }

    pub async fn start_txn(&self) {
        MODE_CHANNEL.send(ModeEvent::StartTxn).await;
    }

    pub async fn consume(&self, byte: u8) {
        MODE_CHANNEL.send(ModeEvent::Consume(byte)).await;
    }

    pub async fn end_txn(&self) {
        MODE_CHANNEL.send(ModeEvent::EndTxn).await;
    }

    pub async fn switch_mode(&self, mode: u8) {
        MODE_CHANNEL.send(ModeEvent::SwitchMode(mode)).await;
    }
}

pub struct Modes {
    state: ModeTxnState,
    active: ActiveMode,
    text: Text,
    tui: Tui,
}

impl Modes {
    pub fn new() -> Modes {
        Modes {
            state: ModeTxnState::AwaitOpcode,
            active: ActiveMode::Text,
            text: Text::new(),
            tui: Tui::new(),
        }
    }

    pub fn handle(&mut self, event: ModeEvent) {
        match event {
            ModeEvent::StartTxn => self.handle_start_txn(),
            ModeEvent::Consume(byte) => self.handle_consume(byte),
            ModeEvent::EndTxn => self.handle_end_txn(),
            ModeEvent::SwitchMode(mode) => self.handle_mode_switch(mode),
        }
    }

    pub fn handle_start_txn(&mut self) {
        self.state = ModeTxnState::AwaitOpcode;
        match self.active {
            ActiveMode::Text => self.text.start_txn(),
            ActiveMode::Tui => self.tui.start_txn(),
        }
    }

    pub fn handle_consume(&mut self, byte: u8) {
        match self.state {
            ModeTxnState::AwaitOpcode => {
                if byte == SWITCH_MODE_OPCODE {
                    log::info!("modes: switch mode opcode");
                    self.state = ModeTxnState::AwaitMode;
                    return;
                }

                self.state = ModeTxnState::Active;
                match self.active {
                    ActiveMode::Text => self.text.consume(byte),
                    ActiveMode::Tui => self.tui.consume(byte),
                }
            }
            ModeTxnState::AwaitMode => {
                self.handle_mode_switch(byte);
            }
            ModeTxnState::Active => match self.active {
                ActiveMode::Text => self.text.consume(byte),
                ActiveMode::Tui => self.tui.consume(byte),
            },
        }
    }

    pub fn handle_end_txn(&mut self) {
        self.state = ModeTxnState::AwaitOpcode;
        match self.active {
            ActiveMode::Text => self.text.end_txn(),
            ActiveMode::Tui => self.tui.end_txn(),
        }
    }

    fn handle_mode_switch(&mut self, mode: u8) {
        self.active = match mode {
            MODE_TEXT => {
                log::info!("modes: switch to text");
                ActiveMode::Text
            }
            MODE_TUI => {
                log::info!("modes: switch to tui");
                ActiveMode::Tui
            }
            _ => {
                log::info!("modes: unknown mode 0x{:02X}", mode);
                self.state = ModeTxnState::Active;
                return;
            }
        };
        self.reset();
        self.state = ModeTxnState::Active;
    }

    fn reset(&mut self) {
        match self.active {
            ActiveMode::Text => self.text.reset(),
            ActiveMode::Tui => self.tui.reset(),
        }
    }

    fn tick(&mut self) {
        match self.active {
            ActiveMode::Text => self.text.tick(),
            ActiveMode::Tui => self.tui.tick(),
        }
    }

    async fn render(&mut self, display: &mut DisplayHandle) {
        match self.active {
            ActiveMode::Text => self.text.render(display).await,
            ActiveMode::Tui => self.tui.render(display).await,
        }
    }
}

pub fn modes_init(spawner: Spawner) {
    spawner.spawn(modes_task()).unwrap();
}

#[embassy_executor::task]
async fn modes_task() {
    let receiver = MODE_CHANNEL.receiver();
    let mut modes = Modes::new();
    let mut display = DisplayHandle::new();
    let mut tick = Ticker::every(Duration::from_millis(16));

    loop {
        match select(receiver.receive(), tick.next()).await {
            Either::First(event) => {
                modes.handle(event);
            }
            Either::Second(_) => {
                modes.tick();
                modes.render(&mut display).await;
            }
        }
    }
}
