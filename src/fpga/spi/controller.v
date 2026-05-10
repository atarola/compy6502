`default_nettype none

module controller (
    input clk,
    input resb,

    // 6502 interface
    input csb,
    input rdb,
    input wrb,
    input [1:0] reg_select,
    input [7:0] cpu_data_in,
    output reg [7:0] cpu_data_out,
    output cpu_data_oeb,

    // SPI interface
    output sck,
    output mosi,
    input miso,
    output reg [3:0] spi_csb
);
  localparam reg [1:0] RegData = 2'b00;
  localparam reg [1:0] RegConf = 2'b01;
  localparam reg [1:0] RegStatus = 2'b10;

  localparam reg [1:0] SpiCSB0 = 2'b00;
  localparam reg [1:0] SpiCSB1 = 2'b01;
  localparam reg [1:0] SpiCSB2 = 2'b10;
  localparam reg [1:0] SpiCSB3 = 2'b11;

  reg write_toggle;
  reg start_transfer;
  reg [7:0] conf;
  reg [7:0] tx_data;
  reg [7:0] data_temp;
  reg [1:0] reg_temp;

  wire [7:0] rx_data;
  wire write_pos_tick;
  wire write_neg_tick;
  wire write_tick = write_neg_tick | write_pos_tick;
  wire engine_busy;

  assign cpu_data_oeb = !(!csb && !rdb);

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
      .rx_data(rx_data),
      .busy(engine_busy),
      .sck(sck),
      .mosi(mosi),
      .miso(miso)
  );

  always @(*) begin
    if (conf[2]) begin
      case (conf[1:0])
        SpiCSB0: spi_csb = 4'b1110;
        SpiCSB1: spi_csb = 4'b1101;
        SpiCSB2: spi_csb = 4'b1011;
        SpiCSB3: spi_csb = 4'b0111;
        default: spi_csb = 4'b1111;
      endcase
    end else begin
      spi_csb = 4'b1111;
    end

    case (reg_select)
      RegData:   cpu_data_out = rx_data;
      RegStatus: cpu_data_out = {7'b0000000, engine_busy};
      RegConf:   cpu_data_out = conf;
      default:   cpu_data_out = 8'h00;
    endcase
  end

  always @(negedge wrb or negedge resb) begin
    if (!resb) begin
      write_toggle <= 1'b0;
      data_temp <= 8'h00;
      reg_temp <= 2'b00;
    end else if (!csb) begin
      data_temp <= cpu_data_in;
      reg_temp <= reg_select;
      write_toggle <= !write_toggle;
    end
  end

  always @(posedge clk or negedge resb) begin
    if (!resb) begin
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
