`default_nettype none

module top (
    input  CLK,
    output USBPU,
    output LED
);

  assign USBPU = 0;

  always @(posedge CLK) begin

  end
endmodule
