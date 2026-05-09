`timescale 1ns / 1ps

/**
 * Spec: byte_engine happy-path byte transfer.
 *
 * Verify a complete nominal transfer: reset, select a chip, start one byte,
 * transmit tx_data on MOSI, receive a MISO byte into rx_data, assert done, and
 * return to idle.
 */
module byte_engine_happy_path_tb;
endmodule
