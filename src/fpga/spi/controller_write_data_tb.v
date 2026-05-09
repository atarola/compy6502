`timescale 1ns / 1ps

/**
 * Spec: controller data-register write starts a byte transfer.
 *
 * Verify that a 6502 write to the data register captures data_bus, synchronizes
 * the write event into clk, loads byte_engine tx_data, and pulses start.
 */
module controller_write_data_tb;
endmodule
