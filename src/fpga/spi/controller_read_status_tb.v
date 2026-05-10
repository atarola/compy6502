`timescale 1ns / 1ps

/**
 * Spec: controller status-register read.
 *
 * Verify that a 6502 read from the status register reports byte_engine busy in
 * bit 0 and zeroes the unused status bits for now.
 */
module controller_read_status_tb;
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
    $dumpfile("build/fpga/spi/controller_read_status_tb.vcd");
    $dumpvars(0, controller_read_status_tb);

    miso = 1;
    cpu_data_in = 8'h00;
    reg_select = uut.RegStatus;

    @(posedge clk);
    resb = 0;
    @(posedge clk);
    resb = 1;

    @(posedge clk);
    csb = 0;
    rdb = 0;
    wrb = 1;
    #1;
    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb low during selected status read, got %b", cpu_data_oeb);
      $finish;
    end
    if (cpu_data_out !== 8'h00) begin
      $display("FAIL: expected status 8'h00 after reset, got %b", cpu_data_out);
      $finish;
    end

    csb = 1;
    rdb = 1;
    #1;
    if (cpu_data_oeb !== 1'b1) begin
      $display("FAIL: expected cpu_data_oeb high when read is inactive, got %b", cpu_data_oeb);
      $finish;
    end

    reg_select = uut.RegData;
    csb = 0;
    rdb = 1;
    wrb = 0;
    cpu_data_in = 8'hA5;
    repeat (3) @(posedge clk);

    reg_select = uut.RegStatus;
    csb = 0;
    rdb = 0;
    wrb = 1;
    repeat (3) @(posedge clk);

    if (cpu_data_oeb !== 1'b0) begin
      $display("FAIL: expected cpu_data_oeb low during selected status read, got %b", cpu_data_oeb);
      $finish;
    end
    if (cpu_data_out !== 8'h01) begin
      $display("FAIL: expected status busy=1 after starting transfer, got %b", cpu_data_out);
      $finish;
    end

    wait (cpu_data_out[0] == 1'b0);
    if (cpu_data_out !== 8'h00) begin
      $display("FAIL: expected status busy=0 after transfer completes, got %b", cpu_data_out);
      $finish;
    end

    csb = 1;
    rdb = 1;
    #1;
    if (cpu_data_oeb !== 1'b1) begin
      $display("FAIL: expected cpu_data_oeb high when read is inactive, got %b", cpu_data_oeb);
      $finish;
    end

    $display("PASS");
    $finish;
  end
endmodule
