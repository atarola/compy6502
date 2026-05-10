`timescale 1ns / 1ps

/**
 * Spec: controller 6502 data-bus ownership.
 *
 * Verify that the controller asserts cpu_data_oeb only during selected reads
 * and drives cpu_data_out with the selected register value.
 */
module controller_bus_drive_tb;
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
    $dumpfile("build/fpga/spi/controller_bus_drive_tb.vcd");
    $dumpvars(0, controller_bus_drive_tb);

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    @(posedge clk);
    reg_select = uut.RegData;
    csb = 0;
    wrb = 0;
    rdb = 1;

    #1;

    if (cpu_data_oeb !== 1'b1) begin
      $display("FAIL: expected cpu_data_oeb high on write cycle, got %b", cpu_data_oeb);
      $finish;
    end

    csb = 0;
    wrb = 1;
    rdb = 0;

    #1;

    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb low on read cycle, got %b", cpu_data_oeb);
      $finish;
    end

    if (cpu_data_out !== 8'h00) begin
      $display("FAIL: expected cpu_data_out to be 8'h00 on csb and rdb asserted, got %b", cpu_data_out);
      $finish;
    end

    @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
