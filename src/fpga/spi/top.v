`default_nettype none

module top (
    input CLK,
    output LED,
    output USBPU,
    input [1:0] REG_SELECT,
    input RESB,
    input WRB,
    input RDB,
    inout [7:0] DATA,
    output DATA_OUT,
    input CSB,
    output [3:0] SPI_CSB,
    output SCK,
    output MOSI,
  input MISO
);

  assign USBPU = 0;

  wire cpu_data_oeb;
  wire [7:0] cpu_data_in;
  wire [7:0] cpu_data_out;
  wire [7:0] debug_write_data;
  wire debug_write_tick;
  wire data_output_enable = !cpu_data_oeb;
  wire spi_select_active = ~&SPI_CSB;
  assign DATA_OUT = !cpu_data_oeb;
  assign LED = spi_select_active;
  assign DATA[7] = data_output_enable ? cpu_data_out[7] : 1'bz;
  assign DATA[6] = data_output_enable ? cpu_data_out[6] : 1'bz;
  assign DATA[5] = data_output_enable ? cpu_data_out[5] : 1'bz;
  assign DATA[4] = data_output_enable ? cpu_data_out[4] : 1'bz;
  assign DATA[3] = data_output_enable ? cpu_data_out[3] : 1'bz;
  assign DATA[2] = data_output_enable ? cpu_data_out[2] : 1'bz;
  assign DATA[1] = data_output_enable ? cpu_data_out[1] : 1'bz;
  assign DATA[0] = data_output_enable ? cpu_data_out[0] : 1'bz;
  assign cpu_data_in = DATA;

  controller spi (
      .clk(CLK),
      .resb(RESB),
      .csb(CSB),
      .rdb(WRB),
      .wrb(RDB),
      .reg_select(REG_SELECT),
      .cpu_data_in(cpu_data_in),
      .cpu_data_out(cpu_data_out),
      .cpu_data_oeb(cpu_data_oeb),
      .debug_write_data(debug_write_data),
      .debug_write_tick(debug_write_tick),
      .sck(SCK),
      .mosi(MOSI),
      .miso(MISO),
      .spi_csb(SPI_CSB)
  );
endmodule
