use embassy_executor::Spawner;
use embassy_futures::select::{Either, select};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::Channel;
use embassy_time::{Duration, Ticker};

use crate::display::DisplayHandle;
use crate::modes::CommandBuffer;
use crate::modes::DisplayMode;
use crate::modes::text::Text;

const SWITCH_MODE_OPCODE: u8 = 0xFF;
const MODE_TEXT: u8 = 0x00;

#[derive(Clone, Copy)]
pub enum ModeEvent {
    StartTxn,
    Consume(u8),
    EndTxn,
}

static MODE_CHANNEL: Channel<CriticalSectionRawMutex, ModeEvent, 256> = Channel::new();

pub struct ModeHandle;

enum ActiveMode {
    Text,
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
}

pub struct Modes {
    buf: CommandBuffer,
    state: ModeTxnState,
    active: ActiveMode,
    text: Text,
}

impl Modes {
    pub fn new() -> Modes {
        Modes {
            buf: CommandBuffer::new(),
            state: ModeTxnState::AwaitOpcode,
            active: ActiveMode::Text,
            text: Text::new(),
        }
    }

    pub fn handle(&mut self, event: ModeEvent) {
        match event {
            ModeEvent::StartTxn => self.handle_start_txn(),
            ModeEvent::Consume(byte) => self.handle_consume(byte),
            ModeEvent::EndTxn => self.handle_end_txn(),
        }
    }

    pub fn handle_start_txn(&mut self) {
        self.buf.clear();
        self.state = ModeTxnState::AwaitOpcode;
        match self.active {
            ActiveMode::Text => self.text.start_txn(&mut self.buf),
        }
    }

    pub fn handle_consume(&mut self, byte: u8) {
        match self.state {
            ModeTxnState::AwaitOpcode => {
                if byte == SWITCH_MODE_OPCODE {
                    self.state = ModeTxnState::AwaitMode;
                    return;
                }

                self.state = ModeTxnState::Active;
                match self.active {
                    ActiveMode::Text => self.text.consume(&mut self.buf, byte),
                }
            }
            ModeTxnState::AwaitMode => {
                self.handle_mode_switch(byte);
            }
            ModeTxnState::Active => match self.active {
                ActiveMode::Text => self.text.consume(&mut self.buf, byte),
            },
        }
    }

    pub fn handle_end_txn(&mut self) {
        self.state = ModeTxnState::AwaitOpcode;
        match self.active {
            ActiveMode::Text => self.text.end_txn(&mut self.buf),
        }
    }

    fn handle_mode_switch(&mut self, mode: u8) {
        self.active = match mode {
            MODE_TEXT => ActiveMode::Text,
            _ => return,
        };
        self.reset();
        self.state = ModeTxnState::Active;
    }

    fn reset(&mut self) {
        match self.active {
            ActiveMode::Text => self.text.reset(),
        }
    }

    fn tick(&mut self) {
        match self.active {
            ActiveMode::Text => self.text.tick(),
        }
    }

    async fn render(&mut self, display: &mut DisplayHandle) {
        match self.active {
            ActiveMode::Text => self.text.render(display).await,
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
