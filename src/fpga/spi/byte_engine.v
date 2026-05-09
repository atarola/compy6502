`default_nettype none

module byte_engine (
    input clk,
    input resb,
    input start,
    input [7:0] tx_data,
    input [1:0] cs_select,
    output [7:0] rx_data,
    output reg busy,
    output reg sck,
    output mosi,
    input miso,
    output reg [3:0] spi_csb
);
  localparam reg [1:0] StateIdle = 2'b00;
  localparam reg [1:0] StateLoad = 2'b01;
  localparam reg [1:0] StateTransfer = 2'b10;
  localparam reg [1:0] StateDone = 2'b11;

  reg load_enable;
  reg [1:0] state;
  reg [1:0] next_state;
  reg [3:0] bit_count;
  reg [5:0] clk_div;
  reg div_resb;

  wire shift_tick = (clk_div == 6'b111111);
  wire sipo_shift_now = state == StateTransfer && shift_tick && sck == 0;
  wire piso_shift_now = state == StateTransfer && shift_tick && sck == 1;

  binary_counter clock_divider (
      .clk  (clk),
      .resb (div_resb),
      .count(clk_div)
  );

  piso_register piso (
      .clk(clk),
      .resb(resb),
      .load_enable(load_enable),
      .shift_enable(piso_shift_now),
      .parallel_in(tx_data),
      .serial_out(mosi)
  );

  sipo_register sipo (
      .clk(clk),
      .resb(resb),
      .serial_in(miso),
      .shift_enable(sipo_shift_now),
      .parallel_out(rx_data)
  );

  always @(*) begin
    next_state = state;
    load_enable = 1'b0;
    div_resb = 1'b1;

    if (state == StateIdle && start) begin
      next_state = StateLoad;
    end

    if (state == StateLoad) begin
      next_state = StateTransfer;
      load_enable = 1'b1;
      div_resb = 1'b0;
    end

    if (state == StateTransfer) begin
      if (bit_count == 4'd8 && !sck) begin
        next_state = StateDone;
      end
    end

    if (state == StateDone) begin
      next_state = StateIdle;
    end
  end

  always @(posedge clk or negedge resb) begin
    if (!resb) begin
      state <= StateIdle;
      sck <= 1'b0;
      bit_count <= 4'd0;
    end else begin
      state <= next_state;

      if (state == StateTransfer && shift_tick && (bit_count < 4'd8 || sck)) begin
        sck <= !sck;
        if (!sck) begin
          bit_count <= bit_count + 1;
        end
      end

      if (state == StateDone) begin
        bit_count <= 4'd0;
        sck <= 1'b0;
      end
    end
  end
endmodule
