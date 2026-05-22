`timescale 1ns / 1ps

/**
 * Spec: byte_engine programmable clock divider.
 *
 * Verify that the programmed divider changes the SCK period and that the
 * divider is latched per transfer.
 */
module byte_engine_clk_divider_tb;
  reg clk = 0;
  reg resb = 1;
  reg start = 0;
  reg [7:0] tx_data = 8'h00;
  reg [5:0] clk_divider = 6'd63;
  reg miso = 0;
  time edge_time = 0;
  time slow_period = 0;
  time fast_period = 0;

  wire [7:0] rx_data;
  wire busy;
  wire sck;
  wire mosi;

  byte_engine uut (
      .clk(clk),
      .resb(resb),
      .start(start),
      .tx_data(tx_data),
      .clk_divider(clk_divider),
      .rx_data(rx_data),
      .busy(busy),
      .sck(sck),
      .mosi(mosi),
      .miso(miso)
  );

  always #31.25 clk = ~clk;

  task start_transfer_and_measure_period;
    input [5:0] divider;
    output time measured_period;
    begin
      clk_divider = divider;

      @(negedge clk);
      start = 1;

      @(negedge clk);
      start = 0;

      @(posedge sck);
      edge_time = $time;

      @(posedge sck);
      measured_period = $time - edge_time;

      wait (!busy);
      @(posedge clk);
    end
  endtask

  initial begin
    repeat (10000) @(posedge clk);
    $display("FAIL: timeout");
    $finish;
  end

  initial begin
    $dumpfile("build/fpga/spi/byte_engine_clk_divider_tb.vcd");
    $dumpvars(0, byte_engine_clk_divider_tb);

    @(posedge clk);
    resb = 0;

    @(posedge clk);
    resb = 1;

    tx_data = 8'hA5;
    start_transfer_and_measure_period(6'd63, slow_period);
    if (slow_period !== 8000) begin
      $display("FAIL: expected divider 63 to yield 8000 ns per SCK period, got %0t", slow_period);
      $finish;
    end

    tx_data = 8'h3C;
    start_transfer_and_measure_period(6'd7, fast_period);
    if (fast_period !== 1000) begin
      $display("FAIL: expected divider 7 to yield 1000 ns per SCK period, got %0t", fast_period);
      $finish;
    end

    tx_data = 8'h5A;
    clk_divider = 6'd63;

    @(negedge clk);
    start = 1;

    @(negedge clk);
    start = 0;

    @(posedge sck);
    clk_divider = 6'd7;
    edge_time = $time;

    @(posedge sck);
    if (($time - edge_time) !== 8000) begin
      $display("FAIL: expected active divider to stay latched for current transfer, got %0t", $time - edge_time);
      $finish;
    end

    wait (!busy);

    $display("PASS");
    $finish;
  end
endmodule
