## State Machine

    module top_module(
        input clk,
        input areset,    // Asynchronous reset to OFF
        input j,
        input k,
        output out); //  

        parameter A=0, B=1, C=2, D=3;
        reg [1:0] state, next_state;

        // State transition logic
        always @(*) begin
            case(state)
                A: next_state = in ? B : A;
                B: next_state = in ? B : C;
                C: next_state = in ? D : A;
                    D: next_state = in ? B : C;
                default: next_state = A;
            endcase
        end

        // State flip-flops with asynchronous reset
        always @(posedge clk or negedge areset) begin
            if (~areset)
                state <= A;
                    else
                state <= next_state;
        end

        // Output logic
        assign out = (state == D);
    endmodule

## Shift Register

    module top_module (
        input clk,
        input areset,
        input in,
        output out);

        reg [3:0] data;
        assign out = data[0];
        
        always @(posedge clk or negedge reset) begin
            if (~areset)
                data <= 0;
            else
                data <= {in, data[3:1]};
        end
    endmodule

