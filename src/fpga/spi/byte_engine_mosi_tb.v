`timescale 1ns / 1ps

/**
 * Spec: byte_engine MOSI transmit order.
 *
 * Verify that a loaded transmit byte is driven on MOSI most-significant bit
 * first, with each bit stable at the expected SPI clock edge.
 */
module byte_engine_mosi_tb;
  reg clk = 0;
  reg resb = 1;
  reg start = 0;
  reg [7:0] tx_data = 8'h00;
  reg miso = 0;
  reg [7:0] out_bits;

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
    $dumpfile("build/fpga/spi/byte_engine_mosi_tb.vcd");
    $dumpvars(0, byte_engine_mosi_tb);

    resb = 1;
    start = 0;
    tx_data = 8'hA5;
    out_bits = 8'h00;

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
      out_bits = {out_bits[6:0], mosi};
    end

    wait (!busy);
    if (out_bits !== 8'hA5) begin
      $display("FAIL: expected out_bits to be 8b'10100101 from mosi, got %b", out_bits);
      $finish;
    end

    @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
