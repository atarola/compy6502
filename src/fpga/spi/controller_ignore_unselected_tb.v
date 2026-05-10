`timescale 1ns / 1ps

/**
 * Spec: controller ignores bus cycles while unselected.
 *
 * Verify that reads do not drive data_bus and writes do not update controller
 * state when csb is inactive.
 */
module controller_ignore_unselected_tb;
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
    $dumpfile("build/fpga/spi/controller_ignore_unselected_tb.vcd");
    $dumpvars(0, controller_ignore_unselected_tb);

    cpu_data_in = 8'h00;

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(posedge clk);
    reg_select = uut.RegData;
    csb = 1;
    wrb = 1;
    rdb = 0;

    #1;

    if (cpu_data_oeb !== 1'b1) begin
      $display("FAIL: expected cpu_data_oeb high when csb not asserted, got %b", cpu_data_oeb);
      $finish;
    end

    csb = 1;
    wrb = 0;
    rdb = 1;
    cpu_data_in = 8'h55;

    #1;

    csb = 0;
    wrb = 1;
    rdb = 0;
    reg_select = uut.RegStatus;

    #1;

    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb low on status read, got %b", cpu_data_oeb);
      $finish;
    end

    if ((cpu_data_out & 8'h01) == 8'h01) begin
      $display("FAIL: expected no change to state when csb is not asserted, got %b", cpu_data_out);
      $finish;
    end

    @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
