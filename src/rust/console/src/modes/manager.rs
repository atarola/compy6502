use embassy_executor::Spawner;
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::channel::Channel;
use embassy_time::{Duration, Ticker};
use embassy_futures::select::{select, Either};

use crate::display::DisplayHandle;
use crate::modes::CommandBuffer;
use crate::modes::DisplayMode;
use crate::modes::sprite::Sprite;
use crate::modes::text::Text;
use crate::modes::tui::Tui;

const SWITCH_MODE_OPCODE: u8 = 0xFF;
const MODE_TEXT: u8 = 0x00;
const MODE_TUI: u8 = 0x01;
const MODE_SPRITE: u8 = 0x02;

#[derive(Clone, Copy)]
pub enum ModeEvent {
    StartTxn,
    Consume(u8),
    EndTxn,
}

static MODE_CHANNEL: Channel<CriticalSectionRawMutex, ModeEvent, 256> = Channel::new();

pub struct ModeHandle;

#[derive(Clone, Copy)]
enum ModeStrategy {
    Text,
    Tui,
    Sprite,
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
    active: ModeStrategy,
    text: Text,
    tui: Tui,
    sprite: Sprite,
}

impl Modes {
    pub fn new() -> Modes {
        Modes {
            buf: CommandBuffer::new(),
            state: ModeTxnState::AwaitOpcode,
            active: ModeStrategy::Text,
            text: Text::new(),
            tui: Tui::new(),
            sprite: Sprite::new(),
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
        self.start_txn(&mut self.buf);
    }

    pub fn handle_consume(&mut self, byte: u8) {
        match self.state {
            ModeTxnState::AwaitOpcode => {
                if byte == SWITCH_MODE_OPCODE {
                    self.state = ModeTxnState::AwaitMode;
                    return;
                }

                self.state = ModeTxnState::Active;
                self.handle_active_byte(byte);
            }
            ModeTxnState::AwaitMode => {
                self.handle_mode_switch(byte);
            }
            ModeTxnState::Active => {
                self.handle_active_byte(byte);
            }
        }
    }

    pub fn handle_end_txn(&mut self) {
        self.state = ModeTxnState::AwaitOpcode;
        self.end_txn(&mut self.buf);
    }

    fn handle_mode_switch(&mut self, mode: u8) {
        self.active = match mode {
            MODE_TEXT => ModeStrategy::Text,
            MODE_TUI => ModeStrategy::Tui,
            MODE_SPRITE => ModeStrategy::Sprite,
            _ => return,
        };
        self.reset();
        self.state = ModeTxnState::Active;
    }

}

impl DisplayMode for Modes {
    fn reset(&mut self) {
        match self.active {
            ModeStrategy::Text => self.text.reset(),
            ModeStrategy::Tui => self.tui.reset(),
            ModeStrategy::Sprite => self.sprite.reset(),
        }
    }

    fn start_txn(&mut self, buf: &mut CommandBuffer) {
        match self.active {
            ModeStrategy::Text => self.text.start_txn(buf),
            ModeStrategy::Tui => self.tui.start_txn(buf),
            ModeStrategy::Sprite => self.sprite.start_txn(buf),
        }
    }

    fn consume(&mut self, buf: &mut CommandBuffer, byte: u8) {
        match self.active {
            ModeStrategy::Text => self.text.consume(buf, byte),
            ModeStrategy::Tui => self.tui.consume(buf, byte),
            ModeStrategy::Sprite => self.sprite.consume(buf, byte),
        }
    }

    fn end_txn(&mut self, buf: &mut CommandBuffer) {
        match self.active {
            ModeStrategy::Text => self.text.end_txn(buf),
            ModeStrategy::Tui => self.tui.end_txn(buf),
            ModeStrategy::Sprite => self.sprite.end_txn(buf),
        }
    }

    fn tick(&mut self) {
        match self.active {
            ModeStrategy::Text => self.text.tick(),
            ModeStrategy::Tui => self.tui.tick(),
            ModeStrategy::Sprite => self.sprite.tick(),
        }
    }

    async fn render(&mut self, display: &mut DisplayHandle) {
        match self.active {
            ModeStrategy::Text => self.text.render(display).await,
            ModeStrategy::Tui => self.tui.render(display).await,
            ModeStrategy::Sprite => self.sprite.render(display).await,
        }
    }
}

pub async fn modes_init(spawner: &Spawner) {
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
