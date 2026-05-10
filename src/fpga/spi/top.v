`default_nettype none

module top (
    input CLK,
    output USBPU,
    input [1:0] REG_SELECT,
    input RESB,
    input WRB,
    input RDB,
    inout [7:0] DATA,
    input CSB,
    output [3:0] SPI_CSB,
    output SCK,
    output MOSI,
    input MISO
);

  assign USBPU = 0;

  wire cpu_data_oeb;
  wire [7:0] cpu_data_out;
  assign DATA = !cpu_data_oeb ? cpu_data_out : 8'bzzzzzzzz;

  controller spi (
      .clk(CLK),
      .resb(RESB),
      .csb(CSB),
      .rdb(RDB),
      .wrb(WRB),
      .reg_select(REG_SELECT),
      .cpu_data_in(DATA),
      .cpu_data_out(cpu_data_out),
      .cpu_data_oeb(cpu_data_oeb),
      .sck(SCK),
      .mosi(MOSI),
      .miso(MISO),
      .spi_csb(SPI_CSB)
  );
endmodule
