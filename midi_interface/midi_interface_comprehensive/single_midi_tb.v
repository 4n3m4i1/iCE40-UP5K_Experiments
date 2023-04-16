`timescale 1ns/1ps
// Testbench for midi input adapter

module single_midi_tb();
    localparam MIDI_BAUD = 31250;        // 31k250 std midi baud
    localparam MIDI_FRAME_SIZE = 10;     // 8N1 format
    localparam SYSCLK_F = 50000000;       // 50M for testing easier
        // Should be 800
    localparam CLK_PER_MIDI_BIT = (SYSCLK_F / MIDI_BAUD) / 2;
        // 400
    localparam HALF_BIT_PERIOD = CLK_PER_MIDI_BIT / 2;




    reg sys_clk;
    reg sim_midi_dat;
/*
(
    input sys_clk,
    input MIDI_IN,

    output reg [(BYTE_W - 1):0] data_rx,
    output reg is_command,
    output wire new_byte_strobe
*/
    wire [7:0]cmd, data_0, data_1;
    wire cmd_ready, dready;

/*
module midi_interface_adapter
#(
    parameter D_W = 16,
    parameter BYTE_W = 8,
    parameter SYSCLK_F = 48000000
)
(
    input sys_clk,
    input MIDI_IN,
    
    output reg [(BYTE_W - 1):0]MIDI_CMD,
    output reg [(BYTE_W - 1):0]MIDI_DAT_0,
    output reg [(BYTE_W - 1):0]MIDI_DAT_1,

    output reg CMD_READY,
    output reg DATA_READY
);
*/
    midi_interface_adapter
    #(
        .SYSCLK_F(SYSCLK_F)
    ) miadapt (
        .sys_clk(sys_clk),
        .MIDI_IN(sim_midi_dat),
        .MIDI_CMD(cmd),
        .MIDI_DAT_0(data_0),
        .MIDI_DAT_1(data_1),
        .CMD_READY(cmd_ready),
        .DATA_READY(dready)
    );



    initial begin
        // Idle line is high
        sim_midi_dat = 1;
        #50000;
        sim_midi_dat = 0;   #32000;   // Start

        sim_midi_dat = 1;   #32000;   // Bit 0
        sim_midi_dat = 0;   #32000;   // Bit 1
        sim_midi_dat = 0;   #32000;   // Bit 2
        sim_midi_dat = 1;   #32000;   // Bit 3
        sim_midi_dat = 0;   #32000;   // Bit 4
        sim_midi_dat = 0;   #32000;   // Bit 5
        sim_midi_dat = 1;   #32000;   // Bit 6
        sim_midi_dat = 1;   #32000;   // Bit 7
        // No parity
        sim_midi_dat = 1;   #32000;   // Stop Bit

        sim_midi_dat = 0;   #32000;   // Start

        sim_midi_dat = 0;   #32000;   // Bit 0
        sim_midi_dat = 1;   #32000;   // Bit 1
        sim_midi_dat = 1;   #32000;   // Bit 2
        sim_midi_dat = 1;   #32000;   // Bit 3
        sim_midi_dat = 1;   #32000;   // Bit 4
        sim_midi_dat = 1;   #32000;   // Bit 5
        sim_midi_dat = 1;   #32000;   // Bit 6
        sim_midi_dat = 0;   #32000;   // Bit 7
        // No parity
        sim_midi_dat = 1;   #32000;   // Stop Bit

        sim_midi_dat = 0;   #32000;   // Start

        sim_midi_dat = 1;   #32000;   // Bit 0
        sim_midi_dat = 0;   #32000;   // Bit 1
        sim_midi_dat = 1;   #32000;   // Bit 2
        sim_midi_dat = 0;   #32000;   // Bit 3
        sim_midi_dat = 1;   #32000;   // Bit 4
        sim_midi_dat = 0;   #32000;   // Bit 5
        sim_midi_dat = 1;   #32000;   // Bit 6
        sim_midi_dat = 0;   #32000;   // Bit 7
        // No parity
        sim_midi_dat = 1;   #32000;   // Stop Bit

        #50000;

        $finish;
    end


    initial begin
        $dumpfile("single_midi_tb.vcd");
        $dumpvars(0,single_midi_tb);
    end

    initial begin
        sys_clk = 0;
        forever begin
            #10;
            sys_clk <= ~sys_clk;
        end
    end

endmodule


