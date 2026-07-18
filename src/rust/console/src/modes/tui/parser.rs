const TUI_CREATE: u8 = 0x10;
const TUI_REMOVE: u8 = 0x11;
const TUI_SET_PROP: u8 = 0x12;
const TUI_SET_TEXT: u8 = 0x13;
const TUI_ABORT: u8 = 0x1E;
const TUI_COMMIT: u8 = 0x1F;

pub enum Command {
    Create { handle: u8, parent: u8, kind: u8 },
    Remove { handle: u8 },
    SetProp { handle: u8, key: u8, value: u8 },
    SetText { handle: u8, len: u16 },
    Abort,
    Commit,
}

#[derive(Clone, Copy)]
enum State {
    AwaitOpcode,
    Fixed {
        opcode: u8,
        buf: [u8; 3],
        pos: u8,
        len: u8,
    },
    TextHeader {
        buf: [u8; 3],
        pos: u8,
    },
    TextPayload {
        handle: u8,
        len: u16,
        remaining: u16,
    },
}

pub struct Parser {
    state: State,
}

impl Parser {
    pub fn new() -> Parser {
        Parser {
            state: State::AwaitOpcode,
        }
    }

    pub fn feed(&mut self, byte: u8) -> Option<Command> {
        match self.state {
            State::AwaitOpcode => self.on_opcode(byte),
            State::Fixed { .. } => self.on_fixed(byte),
            State::TextHeader { .. } => self.on_text_header(byte),
            State::TextPayload { .. } => self.on_text_payload(),
        }
    }

    fn on_opcode(&mut self, opcode: u8) -> Option<Command> {
        match opcode {
            TUI_CREATE => self.begin_fixed(opcode, 3),
            TUI_REMOVE => self.begin_fixed(opcode, 1),
            TUI_SET_PROP => self.begin_fixed(opcode, 3),
            TUI_SET_TEXT => {
                self.state = State::TextHeader {
                    buf: [0; 3],
                    pos: 0,
                };
                None
            }
            TUI_ABORT => Some(Command::Abort),
            TUI_COMMIT => Some(Command::Commit),
            _ => None,
        }
    }

    fn begin_fixed(&mut self, opcode: u8, len: u8) -> Option<Command> {
        self.state = State::Fixed {
            opcode,
            buf: [0; 3],
            pos: 0,
            len,
        };
        None
    }

    fn on_fixed(&mut self, byte: u8) -> Option<Command> {
        let State::Fixed {
            opcode,
            mut buf,
            mut pos,
            len,
        } = self.state
        else {
            return None;
        };

        buf[pos as usize] = byte;
        pos += 1;

        if pos < len {
            self.state = State::Fixed {
                opcode,
                buf,
                pos,
                len,
            };
            return None;
        }

        self.state = State::AwaitOpcode;
        match opcode {
            TUI_CREATE => Some(Command::Create {
                handle: buf[0],
                parent: buf[1],
                kind: buf[2],
            }),
            TUI_REMOVE => Some(Command::Remove { handle: buf[0] }),
            TUI_SET_PROP => Some(Command::SetProp {
                handle: buf[0],
                key: buf[1],
                value: buf[2],
            }),
            _ => None,
        }
    }

    fn on_text_header(&mut self, byte: u8) -> Option<Command> {
        let State::TextHeader { mut buf, mut pos } = self.state else {
            return None;
        };

        buf[pos as usize] = byte;
        pos += 1;

        if pos < 3 {
            self.state = State::TextHeader { buf, pos };
            return None;
        }

        let len = u16::from_le_bytes([buf[1], buf[2]]);
        if len == 0 {
            self.state = State::AwaitOpcode;
            return Some(Command::SetText {
                handle: buf[0],
                len,
            });
        }

        self.state = State::TextPayload {
            handle: buf[0],
            len,
            remaining: len,
        };
        None
    }

    fn on_text_payload(&mut self) -> Option<Command> {
        let State::TextPayload {
            handle,
            len,
            mut remaining,
        } = self.state
        else {
            return None;
        };

        remaining -= 1;
        if remaining > 0 {
            self.state = State::TextPayload {
                handle,
                len,
                remaining,
            };
            return None;
        }

        self.state = State::AwaitOpcode;
        Some(Command::SetText { handle, len })
    }
}
