`timescale 1ns/1ps


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
    wire [7:0]data;
    wire data_is_cmd;

    single_midi_in
    #(
        .SYSCLK_F(SYSCLK_F)
    ) MIDI_RX (
        .sys_clk(sys_clk),
        .MIDI_IN(sim_midi_dat),

        .data_rx(data),
        .is_command(data_is_cmd)
    );




    initial begin
        // Idle line is high
        sim_midi_dat = 1;
        #20000;
        sim_midi_dat = 0;   #16000;   // Start

        sim_midi_dat = 1;   #16000;   // Bit 0
        sim_midi_dat = 0;   #16000;   // Bit 1
        sim_midi_dat = 0;   #16000;   // Bit 2
        sim_midi_dat = 1;   #16000;   // Bit 3
        sim_midi_dat = 0;   #16000;   // Bit 4
        sim_midi_dat = 0;   #16000;   // Bit 5
        sim_midi_dat = 1;   #16000;   // Bit 6
        sim_midi_dat = 1;   #16000;   // Bit 7
        // No parity
        sim_midi_dat = 1;   #16000;   // Stop Bit

        #20000;

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


