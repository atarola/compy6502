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
  reg [1:0] cs_select = 2'b00;
  reg miso = 0;
  reg [7:0] out_bits;

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
    cs_select = 2'b00;
    out_bits = 8'h00;

    // Reset the engine before starting the transfer.
    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(negedge clk);
    start = 1;

    @(negedge clk);
    start = 0;

    // Sample the MOSI bit after each rising edge.
    repeat (8) begin
      @(posedge sck);
      #1;
      out_bits = {out_bits[6:0], mosi};
    end

    @(posedge clk);
    #1;
    if (out_bits !== 8'hA5) begin
      $display("FAIL: expected out_bits to be 8b'10100101 from mosi, got %b", out_bits);
      $finish;
    end

    @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
