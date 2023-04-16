//`include "../midi_interface_basic/single_midi_in.v"
/*
    A MIDI interface and control unit that can drive
    a generic audio synthesis pipeline.

    Dividers are provided per voice that are accessed via
    a LUT indexed by MIDI note values

    Other controls such as pitch bend, modulation, and more
    have dedicated outputs.
*/
module FULL_MIDI_INTERFACE
#(
    parameter SYS_CLK_F = 48000000,
    parameter MIDI_BAUD = 31250,
    parameter BYTE_W = 8,
    parameter D_W = 16,
    parameter NUM_VOICES = 4
)
(
    input sys_clk,
    input MIDI_DIN,

    output reg [(D_W - 1):0]VOICE_0_DIV,
    output reg AR_0,
    output reg [(D_W - 1):0]VOICE_1_DIV,
    output reg AR_1,
    output reg [(D_W - 1):0]VOICE_2_DIV,
    output reg AR_2,
    output reg [(D_W - 1):0]VOICE_3_DIV,
    output reg AR_3,

    output reg [(D_W - 1):0]MOD_DIV
);

    localparam CMD_NOTE_OFF = 3'b000;       //4'h8;
    localparam CMD_NOTE_ON  = 3'b001;       //4'h9;
    localparam CMD_POLY_PRESSURE = 3'b010;  //4'hA;
    localparam CMD_CTRL_CHANGE = 3'b011;    //4'hB;
    localparam CMD_PROG_CHANGE = 3'b100;    //4'hC;
    localparam CMD_CHAN_PRESSURE = 3'b101;  //4'hD;
    localparam CMD_PITCH_BEND = 3'b110;     //4'hE;
    localparam CMD_SYSTEM_MESSAGE = 3'b111; //4'hF;


    localparam IDLE_STATE           = 2'b00;
    localparam APPLY_NOTE_CHANGE    = 2'b01;
    localparam LOAD_NOTE_CHANGE     = 2'b10;
    localparam CLEANUP_NOTE_CHANGE  = 2'b11;


    localparam KEY_PRESSED = 1'b1;
    localparam KEY_RELEASED = 1'b0;

    
    reg [(BYTE_W - 1):0]note_number;
    wire [(D_W - 1):0]note_div_val;
    note_LUT note_lut_main
    (
        .bram_clk(~sys_clk),
        .bram_ce(1'b1),
        .bram_addr(note_number),
        .bram_out(note_div_val)
    );

    // Midi interface
    wire midi_data_ready, midi_is_command;
    wire [(BYTE_W - 1):0]midi_in;
    single_midi_in midi_input_interface
    (
        .sys_clk(sys_clk),
        .MIDI_IN(MIDI_DIN),

        .data_rx(midi_in),
        .is_command(midi_is_command),
        .new_byte_strobe(midi_data_ready)
    );

    reg [(BYTE_W - 1):0] midi_data_0, midi_data_1;
    reg [3:0]midi_channel;
    reg [2:0]midi_command;
    reg [1:0]geneneral_state;
    reg [1:0]in_byte_ct;

    reg [1:0]note_application_state;
    reg [1:0]note_shutdown_state;

    initial begin
        note_number = {BYTE_W{1'b0}};

        //midi_in = {BYTE_W{1'b0}};
        midi_command = {3{1'b0}};
        midi_channel = {4{1'b0}};
        midi_data_0 = {BYTE_W{1'b0}};
        midi_data_1 = {BYTE_W{1'b0}};

        geneneral_state = 2'b00;
        note_application_state = 2'b00;
        note_shutdown_state = 2'b00;
        in_byte_ct = 2'b00;


        VOICE_0_DIV = {D_W{1'b0}};
        AR_0 = 1'b0;
        VOICE_1_DIV = {D_W{1'b0}};
        AR_1 = 1'b0;
        VOICE_2_DIV = {D_W{1'b0}};
        AR_2 = 1'b0;
        VOICE_3_DIV = {D_W{1'b0}};
        AR_3 = 1'b0;

        MOD_DIV = {D_W{1'b0}};
    end

    always @ (posedge sys_clk) begin
        if(midi_data_ready) begin
            if(midi_is_command) begin
                midi_command <= midi_in[6:4];
                midi_channel <= midi_in[3:0];
            end
            else if(in_byte_ct == 2'b01) begin
                midi_data_1 <= midi_in;
                in_byte_ct <= in_byte_ct + 1;
            end
            else begin
                midi_data_0 <= midi_in;
                in_byte_ct <= in_byte_ct + 1;
            end
        end
        
        
        case (midi_command)
            CMD_NOTE_OFF: if(in_byte_ct == 2'b10) note_shutdown_state <= APPLY_NOTE_CHANGE;
            CMD_NOTE_ON:  if(in_byte_ct == 2'b10) note_application_state <= APPLY_NOTE_CHANGE;
            /*
            CMD_POLY_PRESSURE:
            CMD_CTRL_CHANGE:
            CMD_PROG_CHANGE:
            CMD_CHAN_PRESSURE:
            CMD_PITCH_BEND:
            CMD_SYSTEM_MESSAGE:
            */
        endcase

        // Note ON message
        case (note_application_state)
            //IDLE_STATE:
            APPLY_NOTE_CHANGE: begin
                note_number <= midi_data_0;
                note_application_state <= LOAD_NOTE_CHANGE;
            end
            LOAD_NOTE_CHANGE: begin
                case(midi_channel)
                    0: begin
                        VOICE_0_DIV <= note_div_val; 
                        AR_0 = KEY_PRESSED;
                    end
                    1: begin
                        VOICE_1_DIV <= note_div_val; 
                        AR_1 = KEY_PRESSED;
                    end
                    2: begin
                        VOICE_2_DIV <= note_div_val; 
                        AR_2 = KEY_PRESSED;
                    end
                    3: begin
                        VOICE_3_DIV <= note_div_val; 
                        AR_3 = KEY_PRESSED;
                    end
                endcase
            end
            CLEANUP_NOTE_CHANGE: begin
                in_byte_ct <= 2'b00;
                note_application_state <= IDLE_STATE;
            end
        endcase

        // Note OFF message
        case (note_shutdown_state)
            //IDLE_STATE:
            APPLY_NOTE_CHANGE: note_shutdown_state <= LOAD_NOTE_CHANGE;
            LOAD_NOTE_CHANGE: begin
                case(midi_channel)
                    0: begin
                        VOICE_0_DIV <= {16{1'b0}}; 
                        AR_0 = KEY_RELEASED;
                    end
                    1: begin
                        VOICE_1_DIV <= {16{1'b0}}; 
                        AR_1 = KEY_RELEASED;
                    end
                    2: begin
                        VOICE_2_DIV <= {16{1'b0}}; 
                        AR_2 = KEY_RELEASED;
                    end
                    3: begin
                        VOICE_3_DIV <= {16{1'b0}}; 
                        AR_3 = KEY_RELEASED;
                    end
                endcase
            end
            CLEANUP_NOTE_CHANGE: begin
                in_byte_ct <= 2'b00;
                note_shutdown_state <= IDLE_STATE;
            end
        endcase

    end
endmodule


