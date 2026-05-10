`timescale 1ns / 1ps

/**
 * Spec: controller configuration-register write.
 *
 * Verify that a 6502 write to the configuration register captures data_bus and
 * updates conf without starting a byte transfer.
 */
module controller_write_conf_tb;
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
    $dumpfile("build/fpga/spi/controller_write_conf_tb.vcd");
    $dumpvars(0, controller_write_conf_tb);

    @(posedge clk);
    resb = 0;
    @(posedge clk);
    resb = 1;

    @(posedge clk);
    reg_select = uut.RegConf;
    csb = 0;
    rdb = 1;
    wrb = 0;
    cpu_data_in = 8'h5A;

    repeat (3) @(posedge clk);

    reg_select = uut.RegConf;
    csb = 0;
    rdb = 0;
    wrb = 1;
    repeat (3) @(posedge clk);
    #1;
    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb low during selected read, got %b", cpu_data_oeb);
      $finish;
    end
    if (cpu_data_out !== 8'h5A) begin
      $display("FAIL: expected conf readback 8'h5A, got %b", cpu_data_out);
      $finish;
    end

    reg_select = uut.RegStatus;
    #1;
    if (cpu_data_out !== 8'h00) begin
      $display("FAIL: expected status busy=0 after conf write, got %b", cpu_data_out);
      $finish;
    end

    $display("PASS");
    $finish;
  end
endmodule
