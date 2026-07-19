use embassy_executor::Spawner;
use embassy_futures::select::{Either, select};
use embassy_time::{Duration, Ticker};

use crate::display::DisplayHandle;
use crate::host;
use crate::modes::DisplayMode;
use crate::modes::text::Text;
use crate::modes::tui::Tui;

const SWITCH_MODE_OPCODE: u8 = 0xFF;
const MODE_TEXT: u8 = 0x00;
const MODE_TUI: u8 = 0x01;

enum ActiveMode {
    Text,
    Tui,
}

enum ModeTxnState {
    AwaitOpcode,
    AwaitMode,
    Active,
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

    fn handle_txn(&mut self, txn: &host::HostTxn) {
        self.handle_txn_bytes(txn.as_slice());
    }

    fn handle_txn_bytes(&mut self, bytes: &[u8]) {
        self.state = ModeTxnState::AwaitOpcode;

        match bytes.first().copied() {
            Some(SWITCH_MODE_OPCODE) => {
                if let Some(&mode) = bytes.get(1) {
                    self.handle_mode_switch(mode);
                }
                self.state = ModeTxnState::AwaitOpcode;
                return;
            }
            Some(_) => {}
            None => return,
        }

        match self.active {
            ActiveMode::Text => self.text.consume_txn(bytes),
            ActiveMode::Tui => self.tui.consume_txn(bytes),
        }

        self.state = ModeTxnState::AwaitOpcode;
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
    let mut modes = Modes::new();
    let mut display = DisplayHandle::new();
    let mut tick = Ticker::every(Duration::from_millis(16));
    let mut render_pending = false;

    loop {
        match select(host::receive_txn(), tick.next()).await {
            Either::First(txn) => {
                modes.handle_txn(&txn);
                while let Some(txn) = host::try_receive_txn() {
                    modes.handle_txn(&txn);
                }
            }
            Either::Second(_) => {
                render_pending = true;
            }
        }

        while let Some(txn) = host::try_receive_txn() {
            modes.handle_txn(&txn);
        }

        if render_pending {
            match select(host::receive_txn(), async {}).await {
                Either::First(txn) => {
                    modes.handle_txn(&txn);
                    while let Some(txn) = host::try_receive_txn() {
                        modes.handle_txn(&txn);
                    }
                }
                Either::Second(_) => {
                    render_pending = false;
                    modes.tick();
                    modes.render(&mut display).await;
                }
            }
        }
    }
}
