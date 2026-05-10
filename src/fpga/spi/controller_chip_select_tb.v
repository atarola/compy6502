`timescale 1ns / 1ps

/**
 * Spec: controller chip-select decode.
 *
 * Verify that spi_csb stays inactive when conf[2] is low and decodes conf[1:0]
 * when conf[2] is high.
 */
module controller_chip_select_tb;
  reg clk = 0;
  reg resb = 1;
  reg csb = 1;
  reg rdb = 1;
  reg wrb = 1;
  reg [1:0] reg_select = 2'b00;
  reg miso = 0;
  reg [7:0] cpu_data_in = 8'h00;

  reg [3:0] spi_csb_0;
  reg [3:0] spi_csb_1;
  reg [3:0] spi_csb_2;
  reg [3:0] spi_csb_3;

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

  task run_controller;
    input [7:0] con;
    output [3:0] csb_value;
    begin
      @(posedge clk);
      reg_select = uut.RegConf;
      csb = 0;
      rdb = 1;
      wrb = 0;
      cpu_data_in = con;

      repeat (3) @(posedge clk);

      @(posedge clk);
      wrb = 1;

      @(posedge clk);
      reg_select = uut.RegData;
      csb = 0;
      rdb = 1;
      wrb = 0;
      cpu_data_in = 8'hFF;

      repeat (3) @(posedge clk);

      reg_select = uut.RegStatus;
      csb = 0;
      rdb = 0;
      wrb = 1;

      repeat (3) @(posedge clk);

      wait (cpu_data_out[0] == 1'b1);
      csb_value = spi_csb;

      wait (cpu_data_out[0] == 1'b0);
      if (cpu_data_out !== 8'h00) begin
        $display("FAIL: expected status busy=0 after transfer completes, got %b", cpu_data_out);
        $finish;
      end
    end
  endtask

  initial begin
    repeat (10000) @(posedge clk);
    $display("FAIL: timeout");
    $finish;
  end

  initial begin
    $dumpfile("build/fpga/spi/controller_chip_select_tb.vcd");
    $dumpvars(0, controller_chip_select_tb);

    @(posedge clk);
    resb = 0;
    @(posedge clk);
    resb = 1;

    // default chip select
    if (spi_csb !== 4'b1111) begin
      $display("FAIL: expected spi_csb to be 1111, got %b", spi_csb);
      $finish;
    end

    // spi_csb = 1110 (conf[2]=1, conf[1:0]=00)
    run_controller(8'h04, spi_csb_0);
    if (spi_csb_0 !== 4'b1110) begin
      $display("FAIL: expected spi_csb to be 1110, got %b", spi_csb_0);
      $finish;
    end

    // spi_csb = 1101 (conf[2]=1, conf[1:0]=01)
    run_controller(8'h05, spi_csb_1);
    if (spi_csb_1 !== 4'b1101) begin
      $display("FAIL: expected spi_csb to be 1101, got %b", spi_csb_1);
      $finish;
    end

    // spi_csb = 1011 (conf[2]=1, conf[1:0]=10)
    run_controller(8'h06, spi_csb_2);
    if (spi_csb_2 !== 4'b1011) begin
      $display("FAIL: expected spi_csb to be 1011, got %b", spi_csb_2);
      $finish;
    end

    // spi_csb = 0111 (conf[2]=1, conf[1:0]=11)
    run_controller(8'h07, spi_csb_3);
    if (spi_csb_3 !== 4'b0111) begin
      $display("FAIL: expected spi_csb to be 0111, got %b", spi_csb_3);
      $finish;
    end

    // clear conf[2] and verify default inactive chip select
    @(posedge clk);
    reg_select = uut.RegConf;
    csb = 0;
    rdb = 1;
    wrb = 0;
    cpu_data_in = 8'h00;
    repeat (3) @(posedge clk);
    wrb = 1;
    repeat (3) @(posedge clk);

    if (spi_csb !== 4'b1111) begin
      $display("FAIL: expected spi_csb to be 1111, got %b", spi_csb);
      $finish;
    end

    $display("PASS");
    $finish;
  end
endmodule
