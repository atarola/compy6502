`timescale 1ns / 1ps

/**
 * Spec: controller configuration-register read.
 *
 * Verify that a 6502 read from the configuration register drives cpu_data_out
 * with the current conf value when cpu_data_oeb is asserted.
 */
module controller_read_conf_tb;
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
    $dumpfile("build/fpga/spi/controller_read_conf_tb.vcd");
    $dumpvars(0, controller_read_conf_tb);

    cpu_data_in = 8'hAA;

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(posedge clk);
    reg_select = uut.RegConf;
    csb = 0;
    wrb = 1;
    rdb = 0;

    repeat (3) @(posedge clk);

    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb low during selected read, got %b", cpu_data_oeb);
      $finish;
    end

    if (cpu_data_out !== 8'h00) begin
      $display("FAIL: expected cpu_data_out to all zeros after reset, got %b", cpu_data_out);
      $finish;
    end

    csb = 0;
    wrb = 1;
    rdb = 1;
    cpu_data_in = 8'h55;

    @(negedge clk);
    wrb = 0;
    #1;
    wrb = 1;

    repeat (3) @(posedge clk);

    csb = 0;
    wrb = 1;
    rdb = 0;
    cpu_data_in = 8'hFF;

    repeat (3) @(posedge clk);

    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb low during selected read, got %b", cpu_data_oeb);
      $finish;
    end

    if (cpu_data_out !== 8'h55) begin
      $display("FAIL: expected output to be 01010101, got %b", cpu_data_out);
      $finish;
    end

    repeat (10) @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
