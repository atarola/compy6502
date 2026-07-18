use embassy_executor::{Executor, Spawner};
use embassy_rp::Peri;
use embassy_rp::multicore::{Stack, spawn_core1};
use embassy_rp::peripherals::{CORE1, PIN_0, PIN_1, PIN_2, PIN_3, PIO0};
use embassy_rp::pio::{Config, Direction as PioDirection, Pio, ShiftDirection};
use static_cell::StaticCell;

use crate::keyboard::KeyboardHandle;
use crate::modes::ModeHandle;

const CMD_READ_STATUS: u8 = 0x01;
const CMD_GET_CHAR: u8 = 0x20;

fn decode_rx(word: u32) -> u8 {
    (word & 0xff) as u8
}

static mut CORE1_STACK: Stack<4096> = Stack::new();

pub fn host_init(
    _spawner: Spawner,
    core1: Peri<'static, CORE1>,
    pio0: Pio<'static, PIO0>,
    pin_miso: Peri<'static, PIN_0>,
    pin_cs: Peri<'static, PIN_1>,
    pin_sck: Peri<'static, PIN_2>,
    pin_mosi: Peri<'static, PIN_3>,
) {
    spawn_core1(core1, unsafe { &mut *(&raw mut CORE1_STACK) }, move || {
        static EXECUTOR: StaticCell<Executor> = StaticCell::new();
        EXECUTOR.init(Executor::new()).run(|spawner| {
            spawner
                .spawn(host_task(pio0, pin_miso, pin_cs, pin_sck, pin_mosi))
                .unwrap();
        });
    });
}

#[embassy_executor::task]
async fn host_task(
    pio: Pio<'static, PIO0>,
    pin_miso: Peri<'static, PIN_0>,
    pin_cs: Peri<'static, PIN_1>,
    pin_sck: Peri<'static, PIN_2>,
    pin_mosi: Peri<'static, PIN_3>,
) {
    let spi_prg = ::pio::pio_asm!(
        r#"
            init:
                pull block
                mov isr, null
                wait 1 gpio 1
            capture:
                wait 0 gpio 1
                set x, 7
                jmp bitloop
            byte:
                jmp pin flush
                set x, 7
            bitloop:
                out pins, 1
                wait 1 gpio 2
                in pins, 1
                jmp pin flush
                wait 0 gpio 2
                jmp x-- bitloop
                push
                pull block
                jmp byte
            flush:
                mov isr, null
                jmp capture
        "#
    );
    let mut common = pio.common;
    let mut sm = pio.sm0;
    let pin_miso = common.make_pio_pin(pin_miso);
    let pin_cs = common.make_pio_pin(pin_cs);
    let pin_sck = common.make_pio_pin(pin_sck);
    let pin_mosi = common.make_pio_pin(pin_mosi);
    let spi_prg = common.load_program(&spi_prg.program);

    sm.set_pin_dirs(PioDirection::Out, &[&pin_miso]);
    sm.set_pin_dirs(PioDirection::In, &[&pin_cs, &pin_sck, &pin_mosi]);

    let mut cfg = Config::default();
    cfg.set_in_pins(&[&pin_mosi]);
    cfg.set_out_pins(&[&pin_miso]);
    cfg.set_jmp_pin(&pin_cs);
    cfg.shift_in.direction = ShiftDirection::Left;
    cfg.shift_out.direction = ShiftDirection::Left;
    cfg.use_program(&spi_prg, &[]);
    sm.set_config(&cfg);
    sm.tx().push(0);
    sm.set_enable(true);

    let mode_handle = ModeHandle::new();

    loop {
        let word = sm.rx().wait_pull().await;
        let rx = decode_rx(word);
        let mut next_tx = 0u8;

        match rx {
            0x00 => {}
            CMD_READ_STATUS => {
                next_tx = KeyboardHandle::new().has_data() as u8;
            }
            CMD_GET_CHAR => {
                next_tx = KeyboardHandle::new().get_char().await.unwrap_or(0);
            }
            _ => {
                mode_handle.consume(rx).await;
            }
        }

        sm.tx().wait_push((next_tx as u32) << 24).await;
    }
}
