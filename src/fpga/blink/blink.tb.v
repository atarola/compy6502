`timescale 1ns/1ps

module tb;
    reg CLK = 0;
    wire LED;
    wire USBPU;

    top #(
        .BLINK_COUNTER_MSB(4),
        .BLINK_COUNTER_LSB(0)
    ) uut (
        .CLK(CLK),
        .LED(LED),
        .USBPU(USBPU)
    );

    always #31.25 CLK = ~CLK;

    initial begin
        $dumpfile("build/fpga/blink/blink.vcd");
        $dumpvars(0, tb);

        repeat (256) @(posedge CLK);
        $finish;
    end
endmodule
