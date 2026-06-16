`timescale 1ns / 1ps

/**
 * Spec: multi-byte SPI write containing an $FF data byte transmits all bytes.
 *
 * Reproduces the observed hardware failure where writing $FF to the SPI data
 * register causes subsequent bytes in the same burst to be dropped.  Sends
 * five bytes ($11 $22 $33 $FF $44) through the controller one at a time,
 * polling the status register between each byte (matching the spi_write kernel
 * routine), and verifies all five bytes appear on MOSI.
 */
module controller_ff_multi_tb;
  reg clk = 0;
  reg resb = 1;
  reg csb = 1;
  reg rdb = 1;
  reg wrb = 1;
  reg [1:0] reg_select = 2'b00;
  reg miso = 0;
  reg [7:0] cpu_data_in = 8'h00;

  wire [7:0] cpu_data_out;
  wire cpu_data_oeb;
  wire [7:0] debug_write_data;
  wire debug_write_tick;
  wire sck;
  wire mosi;
  wire [3:0] spi_csb;

  controller uut (
      .clk(clk),
      .resb(resb),
      .csb(csb),
      .rdb(rdb),
      .wrb(wrb),
      .reg_select(reg_select),
      .cpu_data_in(cpu_data_in),
      .cpu_data_out(cpu_data_out),
      .cpu_data_oeb(cpu_data_oeb),
      .debug_write_data(debug_write_data),
      .debug_write_tick(debug_write_tick),
      .sck(sck),
      .mosi(mosi),
      .miso(miso),
      .spi_csb(spi_csb)
  );

  always #31.25 clk = ~clk;

  // capture bytes shifted out on MOSI (MSB first, sample on rising SCK)
  integer byte_count = 0;
  reg [7:0] mosi_captured[0:7];
  reg [3:0] mosi_bit_idx = 0;
  reg [7:0] mosi_shift = 0;

  always @(posedge sck) begin
    mosi_shift = {mosi_shift[6:0], mosi};
    if (mosi_bit_idx == 7) begin
      mosi_captured[byte_count] = mosi_shift;
      byte_count = byte_count + 1;
      mosi_bit_idx = 0;
    end else begin
      mosi_bit_idx = mosi_bit_idx + 1;
    end
  end

  // mirror spi_write: write one byte to DATA reg, poll STATUS until not busy
  task spi_write_byte;
    input [7:0] data;
    begin
      csb = 0;
      reg_select = 2'b00;
      cpu_data_in = data;
      wrb = 0;
      @(posedge clk);
      wrb = 1;
      csb = 1;

      reg_select = 2'b10;
      csb = 0;
      rdb = 0;
      repeat (3) @(posedge clk);
      #1;
      $display("  [%0t] after write %h: busy=%b tick=%b toggle=%b",
               $time, data, cpu_data_out[0], uut.write_tick, uut.write_toggle);
      wait (cpu_data_out[0] == 1'b0);
      rdb = 1;
      csb = 1;
      @(posedge clk);
      $display("  [%0t] byte %h done, mosi bytes so far: %0d", $time, data, byte_count);
    end
  endtask

  initial begin
    repeat (10000) @(posedge clk);
    $display("FAIL: timeout");
    $finish;
  end

  initial begin
    $dumpfile("build/fpga/spi/controller_ff_multi_tb.vcd");
    $dumpvars(0, controller_ff_multi_tb);

    @(posedge clk);
    resb = 0;
    @(posedge clk);
    resb = 1;
    @(posedge clk);

    spi_write_byte(8'h11);
    spi_write_byte(8'h22);
    spi_write_byte(8'h33);
    spi_write_byte(8'hFF);
    spi_write_byte(8'h44);

    if (byte_count !== 5) begin
      $display("FAIL: expected 5 MOSI bytes, got %0d", byte_count);
      $finish;
    end
    if (mosi_captured[0] !== 8'h11) begin
      $display("FAIL: byte 0 expected 11, got %h", mosi_captured[0]);
      $finish;
    end
    if (mosi_captured[1] !== 8'h22) begin
      $display("FAIL: byte 1 expected 22, got %h", mosi_captured[1]);
      $finish;
    end
    if (mosi_captured[2] !== 8'h33) begin
      $display("FAIL: byte 2 expected 33, got %h", mosi_captured[2]);
      $finish;
    end
    if (mosi_captured[3] !== 8'hFF) begin
      $display("FAIL: byte 3 expected FF, got %h", mosi_captured[3]);
      $finish;
    end
    if (mosi_captured[4] !== 8'h44) begin
      $display("FAIL: byte 4 expected 44, got %h", mosi_captured[4]);
      $finish;
    end

    $display("PASS");
    $finish;
  end
endmodule
