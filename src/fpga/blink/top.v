module top #(
    parameter BLINK_COUNTER_MSB = 25,
    parameter BLINK_COUNTER_LSB = 21
) (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU  // USB pull-up resistor
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // keep track of time and location in blink_pattern
    reg [25:0] blink_counter = 0;

    // pattern that will be flashed over the LED over time
    wire [31:0] blink_pattern = 32'b101010001110111011100010101;

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        blink_counter <= blink_counter + 1;
    end
    
    // light up the LED according to the pattern
    assign LED = blink_pattern[blink_counter[BLINK_COUNTER_MSB:BLINK_COUNTER_LSB]];
endmodule
