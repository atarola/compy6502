`timescale 1ns / 1ps

/**
 * Spec: controller data-register read.
 *
 * Verify that a 6502 read from the data register drives data_bus with the last
 * byte received by byte_engine, and releases data_bus when read is inactive.
 */
module controller_read_data_tb;
  reg clk = 0;
  reg resb = 1;
  reg csb = 1;
  reg rdb = 1;
  reg wrb = 1;
  reg [1:0] reg_select = 2'b00;
  reg miso = 0;
  reg [7:0] cpu_data_in;

  wire [7:0] cpu_data_out;
  wire cpu_data_oeb;
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
    $dumpfile("build/fpga/spi/controller_read_data_tb.vcd");
    $dumpvars(0, controller_read_data_tb);

    miso = 1;
    cpu_data_in = 8'h00;

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(posedge clk);
    reg_select = uut.RegData;
    csb = 0;
    wrb = 0;
    rdb = 1;

    repeat (3) @(posedge clk);
    reg_select = uut.RegStatus;
    csb = 0;
    wrb = 1;
    rdb = 0;

    repeat (3) @(posedge clk);
    if (cpu_data_out !== 8'h01) begin
      $display("FAIL: expected cpu_data_out to read busy, got %b", cpu_data_out);
      $finish;
    end

    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb to be asserted");
      $finish;
    end

    wait (cpu_data_out[0] == 1'b0);
    reg_select = uut.RegData;
    csb = 0;
    wrb = 1;
    rdb = 0;

    repeat (3) @(posedge clk);
    if (cpu_data_out !== 8'hFF) begin
      $display("FAIL: expected cpu_data_out to be 11111111, got %b", cpu_data_out);
      $finish;
    end

    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb to be asserted");
      $finish;
    end

    $display("PASS");
    $finish;
  end
endmodule
