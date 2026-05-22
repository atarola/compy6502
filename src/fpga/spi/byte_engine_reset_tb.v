`timescale 1ns / 1ps

/**
 * Spec: byte_engine reset and idle defaults.
 *
 * Verify that reset leaves the engine idle: SCK low, all chip selects inactive,
 * not busy, and receive data cleared or otherwise deterministic.
 *
 * TODO: Add explicit checks for spi_csb and busy once byte_engine drives those
 * outputs.
 */
module byte_engine_reset_tb;
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
      .clk_divider(6'd63),
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
    $dumpfile("build/fpga/spi/byte_engine_reset_tb.vcd");
    $dumpvars(0, byte_engine_reset_tb);

    resb = 1;
    start = 0;
    tx_data = 8'hA5;
    miso = 0;

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(posedge clk);
    start = 1;
    miso  = 1;

    @(posedge clk);
    start = 0;

    @(posedge sck);
    @(posedge clk);
    #1;
    if (rx_data !== 8'h01) begin
      $display("FAIL: expected rx_data to have data from miso, got %b", rx_data);
      $finish;
    end

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(posedge clk);
    #1;
    if (rx_data !== 8'h00) begin
      $display("FAIL: expected rx_data to have no data, got %b", rx_data);
      $finish;
    end

    #90;

    $display("PASS");
    $finish;
  end
endmodule
