`timescale 1ns/1ps

module SR_DEBOUNCE_tb();

    reg sys_clk;


/*
module SR_DB
#(
    parameter SYSCLK_FREQ = 24000000,
    parameter DEBOUNCE_DELAY = 0.150
)(
    input       clk,
    input       D,
    output reg  Q
);
*/
    reg BUTTON;
    wire Q;

    SR_DB #(
        .DEBOUNCE_DELAY(0.0005)
    ) debouncy (
        .clk(sys_clk),
        .D(BUTTON),
        .Q(Q)
    );

    initial begin
        BUTTON = 0;
        #10000;
        BUTTON = 1;
        #500;
        BUTTON = 0;
        #600;
        BUTTON = 1;
        #800;
        BUTTON = 1;
        #400;
        BUTTON = 0;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 0;
        #600;
        BUTTON = 1;
        #800;
        BUTTON = 1;
        #400;
        BUTTON = 0;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 0;
        #600;
        BUTTON = 1;
        #800;
        BUTTON = 1;
        #400;
        BUTTON = 0;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 0;
        #600;
        BUTTON = 1;
        #800;
        BUTTON = 1;
        #400;
        BUTTON = 0;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 0;
        #600;
        BUTTON = 1;
        #800;
        BUTTON = 1;
        #400;
        BUTTON = 0;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 0;
        #600;
        BUTTON = 1;
        #800;
        BUTTON = 1;
        #400;
        BUTTON = 0;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 0;
        #600;
        BUTTON = 1;
        #800;
        BUTTON = 1;
        #400;
        BUTTON = 0;
        #500;
        BUTTON = 1;
        #500;
        BUTTON = 0;

        #1000000;

        $finish;
    end

    initial begin
        $dumpfile("SR_DEBOUNCE_tb.vcd");
        $dumpvars(0,SR_DEBOUNCE_tb);
    end

    initial begin       // 48MHz standin
        sys_clk = 0;
        forever begin
            #20;
            sys_clk <= ~sys_clk;
        end
    end


endmodule