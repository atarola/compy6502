`default_nettype none

module piso_register (
    input clk,
    input resb,
    input load_enable,
    input shift_enable,
    input [7:0] parallel_in,
    output reg serial_out
);
  reg [7:0] data;

  always @(posedge clk or negedge resb) begin
    if (!resb) begin
      serial_out <= 1'b0;
      data <= 8'h00;
    end else begin
      if (load_enable && shift_enable) begin
        data <= {parallel_in[6:0], 1'b0};
        serial_out <= parallel_in[7];
      end else if (load_enable) begin
        data <= {parallel_in[6:0], 1'b0};
        serial_out <= parallel_in[7];
      end else if (shift_enable) begin
        data <= {data[6:0], 1'b0};
        serial_out <= data[7];
      end
    end
  end
endmodule
