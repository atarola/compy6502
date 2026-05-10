`timescale 1ns / 1ps

/**
 * Spec: byte_engine completion and return to idle.
 *
 * Verify that a completed byte transfer clears busy, returns SCK to idle-low,
 * and leaves the received byte available on rx_data.
 */
module byte_engine_idle_tb;
  reg clk = 0;
  reg resb = 1;
  reg start = 0;
  reg [7:0] tx_data = 8'h00;
  reg miso = 0;

  wire [7:0] rx_data;
  wire busy;
  wire sck;
  wire mosi;

  byte_engine uut (
      .clk(clk),
      .resb(resb),
      .start(start),
      .tx_data(tx_data),
      .rx_data(rx_data),
      .busy(busy),
      .sck(sck),
      .mosi(mosi),
      .miso(miso)
  );

  always #31.25 clk = ~clk;

  initial begin
    repeat (10000) @(posedge clk);
    $display("FAIL: timeout");
    $finish;
  end

  initial begin
    $dumpfile("build/fpga/spi/byte_engine_idle_tb.vcd");
    $dumpvars(0, byte_engine_idle_tb);

    resb = 1;
    start = 0;
    tx_data = 8'h00;
    miso = 1;

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(negedge clk);
    start = 1;

    @(negedge clk);
    start = 0;

    repeat (8) begin
      @(posedge sck);
      #1;
      miso = ~miso;
    end

    wait (!busy);

    if (busy !== 1'b0) begin
      $display("FAIL: expected busy to clear after transfer");
      $finish;
    end

    if (sck !== 1'b0) begin
      $display("FAIL: expected sck to return idle-low, got %b", sck);
      $finish;
    end

    if (rx_data !== 8'hAA) begin
      $display("FAIL: expected rx_data to hold 8b'10101010, got %b", rx_data);
      $finish;
    end

    @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
