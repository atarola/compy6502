`timescale 1ns / 1ps

/**
 * Spec: top-level SPI wrapper smoke test.
 *
 * Verify that top-level wiring propagates reset and bus control correctly:
 * USBPU default state, DATA tri-state behavior on write cycles, and DATA drive
 * behavior on selected read cycles.
 */
module top_tb;
  reg CLK = 0;
  reg [1:0] REG_SELECT = 2'b00;
  reg RESB = 1;
  reg WRB = 1;
  reg RDB = 1;
  reg CSB = 1;
  reg MISO = 0;
  reg tb_data_oe = 0;
  reg [7:0] tb_data_drive = 8'h00;

  wire USBPU;
  wire [7:0] DATA = tb_data_oe ? tb_data_drive : 8'bzzzzzzzz;
  wire [3:0] SPI_CSB;
  wire SCK;
  wire MOSI;

  top uut (
      .CLK(CLK),
      .USBPU(USBPU),
      .REG_SELECT(REG_SELECT),
      .RESB(RESB),
      .WRB(WRB),
      .RDB(RDB),
      .DATA(DATA),
      .CSB(CSB),
      .SPI_CSB(SPI_CSB),
      .SCK(SCK),
      .MOSI(MOSI),
      .MISO(MISO)
  );

  always #31.25 CLK = ~CLK;

  initial begin
    repeat (10000) @(posedge CLK);
    $display("FAIL: timeout");
    $finish;
  end

  initial begin
    $dumpfile("build/fpga/spi/top_tb.vcd");
    $dumpvars(0, top_tb);

    @(posedge CLK);
    RESB = 0;
    @(posedge CLK);
    RESB = 1;

    if (USBPU !== 1'b0) begin
      $display("FAIL: expected USBPU low, got %b", USBPU);
      $finish;
    end

    REG_SELECT = 2'b00;
    CSB = 0;
    WRB = 0;
    RDB = 1;
    tb_data_drive = 8'hA5;
    tb_data_oe = 1;
    #1;

    if (DATA !== 8'hA5) begin
      $display("FAIL: expected DATA to follow external drive on write, got %b", DATA);
      $finish;
    end

    tb_data_oe = 0;
    WRB = 1;
    RDB = 0;
    REG_SELECT = 2'b01;
    repeat (3) @(posedge CLK);
    #1;

    if (DATA !== 8'h00) begin
      $display("FAIL: expected DATA to be 8'h00 on reset conf read, got %b", DATA);
      $finish;
    end

    CSB = 1;
    RDB = 1;
    #1;
    if (DATA !== 8'bzzzzzzzz) begin
      $display("FAIL: expected DATA high-Z when read inactive, got %b", DATA);
      $finish;
    end

    $display("PASS");
    $finish;
  end
endmodule
