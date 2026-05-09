`timescale 1ns / 1ps

/**
 * Spec: byte_engine start while busy.
 *
 * Verify that a start pulse during an active transfer is ignored unless a later
 * design explicitly adds queuing.
 */
module byte_engine_busy_start_tb;
endmodule
