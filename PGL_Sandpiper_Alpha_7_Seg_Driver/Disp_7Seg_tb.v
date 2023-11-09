`timescale 1ns/1ps

module Disp_7Seg_tb();

    reg sys_clk;

/*
module PGL_Sandpiper_vAlpha_7Seg_Driver
#(
    parameter SEG_CT = 8,                   // Must be power of 2. Don't change!
    parameter CAN_CT = 8,                   // ^^
    parameter DISPLAY_HZ = 800,
    parameter SYSCLK_F = 24000000,
    parameter DIMMING_STEPS = 256,          // Must be power of 2
    parameter SHIFT_CLK_F = 2000000
)
(
    input en,
    input sys_clk,
    input clear_buffer,
    input commit_char,
    input [(SEG_CT - 1):0] SEGMENTS_2_LIGHT,
    input [(CAN_CT - 1):0] CHAR_SELECTED,
    input [(DIMMING_REG_W - 1):0] CHAR_BRIGHTNESS,

    output reg  SCLK,
    output reg  DOUT,
    output reg  RCLK,
    output wire OE
);
*/
    reg [7:0]segment;
    reg [7:0]bright;
    reg [2:0]char_sel;
    reg commit;
    reg clr,en;

    wire DO,OE,RCLK,SCLK;
    PGL_Sandpiper_vAlpha_7Seg_Driver SPR_DISP
    (
        .en(en),
        .sys_clk(sys_clk),
        .clear_buffer(clr),
        .commit_char(commit),
        .SEGMENTS_2_LIGHT(segment),
        .CHAR_BRIGHTNESS(bright),
        .CHAR_SELECTED(char_sel),
        .SCLK(SCLK),
        .DOUT(DO),
        .RCLK(RCLK),
        .OE(OE)
    );

    initial begin
        en = 0; clr = 0; commit = 0; bright = 0; segment = 0; char_sel = 0;
        #10;
        bright = 127;
        segment = 8'hA5;
        commit = 1;
        #30;
        commit = 0;

        #30;
        en = 1;

        #10000000;

        $finish;
    end


    initial begin
        $dumpfile("Disp_7Seg_tb.vcd");
        $dumpvars(0,Disp_7Seg_tb);
    end

    initial begin       // 48MHz standin
        sys_clk = 0;
        forever begin
            #20;
            sys_clk <= ~sys_clk;
        end
    end
endmodule