`default_nettype none

module sipo_register (
    input clk,
    input resb,
    input serial_in,
    input shift_enable,
    output reg [7:0] parallel_out
);
  always @(posedge clk or negedge resb) begin
    if (!resb) begin
      parallel_out <= 8'h00;
    end else if (shift_enable) begin
      parallel_out <= {parallel_out[6:0], serial_in};
    end
  end
endmodule
