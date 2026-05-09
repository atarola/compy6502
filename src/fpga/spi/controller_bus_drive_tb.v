`timescale 1ns / 1ps

/**
 * Spec: controller 6502 data-bus ownership.
 *
 * Verify that the controller only drives data_bus during selected reads and
 * otherwise leaves the bus high impedance.
 */
module controller_bus_drive_tb;
  reg clk = 0;
  reg resb = 1;
  reg csb = 1;
  reg rdb = 1;
  reg wrb = 1;
  reg [1:0] reg_select = 2'b00;
  reg miso = 0;

  wire [7:0] data_bus;
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
      .data_bus(data_bus),
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

    if (data_bus !== 8'bzzzzzzzz) begin
      $display("FAIL: expected data_bus to be Z on csb and wrb asserted, got %b", data_bus);
      $finish;
    end

    csb = 0;
    wrb = 1;
    rdb = 0;

    #1;

    if (data_bus !== 8'h00) begin
      $display("FAIL: expected data_bus to be 8'h00 on csb and rdb asserted, got %b", data_bus);
      $finish;
    end

    @(posedge clk);

    $display("PASS");
    $finish;
  end
endmodule
