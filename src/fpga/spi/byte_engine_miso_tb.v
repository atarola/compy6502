`timescale 1ns / 1ps

/**
 * Spec: byte_engine MISO receive order.
 *
 * Verify that MISO is sampled on each SCK rising edge and the received byte
 * appears on rx_data after the byte completes.
 */
module byte_engine_miso_tb;
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
    $dumpfile("build/fpga/spi/byte_engine_miso_tb.vcd");
    $dumpvars(0, byte_engine_miso_tb);

    resb = 1;
    start = 0;
    tx_data = 8'hA5;
    miso = 0;

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(negedge clk);
    start = 1;
    miso  = 1;

    @(negedge clk);
    start = 0;

    repeat (8) begin
      @(posedge sck);
      #1;
      miso = ~miso;
    end

    wait (!busy);
    if (rx_data !== 8'hAA) begin
      $display("FAIL: expected rx_data to be 8b'10101010 from miso, got %b", rx_data);
      $finish;
    end

    @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
