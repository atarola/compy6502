`default_nettype none

module synchronizer (
    input clk,
    input resb,
    input in,
    output reg out,
    output reg pos_tick,
    output reg neg_tick
);
  reg [1:0] stages = 2'b00;
  reg prev_value = 1'b0;

  always @(posedge clk or negedge resb) begin
    if (!resb) begin
      stages <= 2'b00;
      prev_value <= 1'b0;
      out <= 1'b0;
      pos_tick <= 1'b0;
      neg_tick <= 1'b0;
    end else begin
      stages <= {stages[0], in};
      out <= stages[1];
      prev_value <= stages[1];
      pos_tick <= (stages[1] == 1) && (prev_value == 0);
      neg_tick <= (stages[1] == 0) && (prev_value == 1);
    end
  end
endmodule
