`default_nettype none

module binary_counter (
    input clk,
    input resb,
    output reg [5:0] count
);
  always @(posedge clk or negedge resb) begin
    if (!resb) begin
      count <= 6'b000000;
    end else begin
      count <= count + 1;
    end
  end
endmodule
