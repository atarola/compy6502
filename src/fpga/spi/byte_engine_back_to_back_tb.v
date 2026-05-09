`timescale 1ns / 1ps

/**
 * Spec: byte_engine back-to-back transfers.
 *
 * Verify that a second transfer after completion starts cleanly, reloads the
 * transmit byte, clears transfer counters, and receives a fresh byte.
 */
module byte_engine_back_to_back_tb;
  reg clk = 0;
  reg resb = 1;
  reg start = 0;
  reg [7:0] tx_data = 8'h00;
  reg [1:0] cs_select = 2'b00;
  reg miso = 0;
  reg [7:0] out_bits;

  wire [7:0] rx_data;
  wire busy;
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
      .sck(sck),
      .mosi(mosi),
      .miso(miso),
      .spi_csb(spi_csb)
  );

  always #31.25 clk = ~clk;

  initial begin
    repeat (10000) @(posedge clk);
    $display("FAIL: timeout");
    $finish;
  end

  initial begin
    $dumpfile("build/fpga/spi/byte_engine_back_to_back_tb.vcd");
    $dumpvars(0, byte_engine_back_to_back_tb);

    resb = 1;
    start = 0;
    tx_data = 8'h55;
    cs_select = 2'b00;
    miso = 0;
    out_bits = 8'h00;

    // Reset the engine before starting the transfer.
    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(negedge clk);
    start = 1;
    miso  = 1;

    @(negedge clk);
    start = 0;

    // Sample the SPI outputs
    repeat (8) begin
      @(posedge sck);
      #1;
      out_bits = {out_bits[6:0], mosi};
      miso = ~miso;
    end

    @(posedge clk);
    #1;
    if (out_bits !== 8'h55) begin
      $display("FAIL: expected out_bits to be 8b'01010101 from mosi, got %b", out_bits);
      $finish;
    end

    if (rx_data !== 8'hAA) begin
      $display("FAIL: expected rx_data to be 8b'10101010 from miso, got %b", rx_data);
      $finish;
    end

    // give it a pause
    @(negedge sck);
    @(posedge clk);
    @(posedge clk);
    @(negedge clk);
    start = 1;
    miso = 0;
    tx_data = 8'hAA;
    out_bits = 8'h00;

    @(negedge clk);
    start = 0;

    // Sample the SPI outputs
    repeat (8) begin
      @(posedge sck);
      #1;
      out_bits = {out_bits[6:0], mosi};
      miso = ~miso;
    end

    @(posedge clk);
    #1;
    if (out_bits !== 8'hAA) begin
      $display("FAIL: expected out_bits to be 8b'10101010 from mosi, got %b", out_bits);
      $finish;
    end

    if (rx_data !== 8'h55) begin
      $display("FAIL: expected rx_data to be 8b'01010101 from miso, got %b", rx_data);
      $finish;
    end

    @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
