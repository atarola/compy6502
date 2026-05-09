`default_nettype none

module controller (
    input clk,
    input resb,

    // 6502 interface
    input csb,
    input rdb,
    input wrb,
    input [1:0] reg_select,
    inout [7:0] data_bus,

    // SPI interface
    output sck,
    output mosi,
    input miso,
    output [3:0] spi_csb
);
  localparam reg [1:0] RegData = 2'b00, RegConf = 2'b01, RegStatus = 2'b10;

  reg write_toggle;
  reg start_transfer;
  reg [7:0] status;
  reg [7:0] conf;
  reg [7:0] read_data;
  reg [7:0] data_temp;
  reg [1:0] reg_temp;
  reg [7:0] tx_data;

  wire [7:0] rx_data;
  wire write_pos_tick;
  wire write_neg_tick;
  wire write_tick = write_neg_tick | write_pos_tick;
  wire engine_busy;

  assign data_bus = (!csb && !rdb) ? read_data : 8'bzzzzzzzz;

  synchronizer write_sync (
      .clk(clk),
      .resb(resb),
      .in(write_toggle),
      .out(),
      .pos_tick(write_pos_tick),
      .neg_tick(write_neg_tick)
  );

  byte_engine spi_engine (
      .clk(clk),
      .resb(resb),
      .start(start_transfer),
      .tx_data(tx_data),
      .cs_select(conf[1:0]),
      .rx_data(rx_data),
      .busy(engine_busy),
      .sck(sck),
      .mosi(mosi),
      .miso(miso),
      .spi_csb(spi_csb)
  );

  always @(*) begin
    case (reg_select)
      RegData:   read_data = rx_data;
      RegStatus: read_data = {7'b0000000, engine_busy};
      RegConf:   read_data = conf;
      default:   read_data = 8'h00;
    endcase
  end

  always @(negedge wrb or negedge resb) begin
    if (!resb) begin
      write_toggle <= 1'b0;
      data_temp <= 8'h00;
      reg_temp <= 2'b00;
    end else if (!csb) begin
      data_temp <= data_bus;
      reg_temp <= reg_select;
      write_toggle <= !write_toggle;
    end
  end

  always @(posedge clk or negedge resb) begin
    if (!resb) begin
      // TODO: choose good defaults
      conf <= 8'h00;
      start_transfer <= 1'b0;
      tx_data <= 8'h00;
    end else begin
      start_transfer <= 1'b0;
      if (write_tick) begin
        if (reg_temp == RegData) begin
          tx_data <= data_temp;
          start_transfer <= 1'b1;
        end

        if (reg_temp == RegConf) begin
          conf <= data_temp;
        end
      end
    end
  end
endmodule
