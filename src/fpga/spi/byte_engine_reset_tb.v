`timescale 1ns / 1ps

/**
 * Spec: byte_engine reset and idle defaults.
 *
 * Verify that reset leaves the engine idle: SCK low, all chip selects inactive,
 * not busy, not done, and receive data cleared or otherwise deterministic.
 *
 * TODO: Add explicit checks for spi_csb, busy, and done once byte_engine drives
 * those outputs.
 */
module byte_engine_reset_tb;
  reg clk = 0;
  reg resb = 1;
  reg start = 0;
  reg [7:0] tx_data = 8'h00;
  reg [1:0] cs_select = 2'b00;
  reg miso = 0;

  wire [7:0] rx_data;
  wire busy;
  wire done;
  wire sck;
  wire mosi;
  wire [3:0] spi_csb;

  byte_engine uut (
      .clk(clk),
      .resb(resb),
      .start(start),
      .tx_data(tx_data),
      .cs_select(cs_select),
      .rx_data(rx_data),
      .busy(busy),
      .done(done),
      .sck(sck),
      .mosi(mosi),
      .miso(miso),
      .spi_csb(spi_csb)
  );

  always #31.25 clk = ~clk;

  initial begin
    $dumpfile("build/fpga/spi/byte_engine_reset_tb.vcd");
    $dumpvars(0, byte_engine_reset_tb);

    resb = 1;
    start = 0;
    tx_data = 8'hA5;
    cs_select = 2'b00;
    miso = 0;

    // quick reset
    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    // Start one transfer
    @(posedge clk);
    start = 1;
    miso  = 1;

    @(posedge clk);
    start = 0;

    // wait for the engine to turn once
    @(posedge sck);
    @(posedge clk);
    #1;
    if (rx_data !== 8'h01) begin
      $display("FAIL: expected rx_data to have data from miso, got %b", rx_data);
      $finish;
    end

    // do a reset
    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    // lets see it clear
    @(posedge clk);
    #1;
    if (rx_data !== 8'h00) begin
      $display("FAIL: expected rx_data to have no data, got %b", rx_data);
      $finish;
    end

    $display("PASS");
    $finish;
  end
endmodule
