


module MIDI_2
#(
    parameter D_W = 16,
    parameter BYTE_W = 8,
    parameter ADDR_W = 8,
    parameter NUM_VOICES = 4
)
(
    input sys_clk,
    input MIDI_DIN,


    output reg [(D_W - 1):0]TDM_VOICE_DATA,
    output reg [1:0]TDM_CHANNEL,
    output reg TDM_CHAN_ENABLED,

    output reg [7:0]curr_div
);
    localparam VOICE_OFF = {D_W{1'b0}};


/*
module note_LUT
#(
    parameter D_W = 16,
    parameter NUM_SAMPLES = 256,
    parameter ADDR_BITS = 8
)
(
    input bram_clk,
    input bram_ce,
    input [(ADDR_BITS - 1):0]bram_addr,
    output reg [(D_W - 1):0]bram_out
);
*/
    reg [(ADDR_W - 1):0]note_number;
    wire [(D_W - 1):0]note_div_out;
    note_LUT notes
    (
        .bram_clk(~sys_clk),
        .bram_ce(1'b1),
        .bram_addr(note_number),
        .bram_out(note_div_out)             // Works!
    );


    wire [(ADDR_W - 1):0]nco_0_addr;
    simple_nco nco_0
    (
        .sys_clk(sys_clk),
        .nco_enable(1'b1),
        .nco_div(note_div_out),
        .nco_addr(nco_0_addr)
    );


    wire [(D_W - 1):0]sin_lut_output;
    fixed_15_sin_bram sin_lut
    (
        .bram_clk(~sys_clk),
        .bram_ce(1'b1),
        .bram_addr(nco_0_addr),
        .bram_out(sin_lut_output)
    );



    wire [7:0]MIDI_COMMAND;
    wire [7:0]MIDI_DATA_0;
    wire [7:0]MIDI_DATA_1;
    wire MIDI_PACKET_READY;
    midi_interface_adapter MIDI_INTER
    (
        .sys_clk(sys_clk),
        .MIDI_IN(MIDI_DIN),
        .MIDI_CMD(MIDI_COMMAND),
        .MIDI_DAT_0(MIDI_DATA_0),
        .MIDI_DAT_1(MIDI_DATA_1),
        //.CMD_READY()
        .DATA_READY(MIDI_PACKET_READY)
    );


    initial begin
        TDM_VOICE_DATA = {D_W{1'b0}};
        TDM_CHANNEL = 2'b00;
        TDM_CHAN_ENABLED = 1'b0;
        curr_div = 8'h00;
    end

    always @ (posedge sys_clk) begin
        if(MIDI_PACKET_READY) begin
            //curr_div <= MIDI_DATA_0;
            curr_div <= note_div_out[8:0];
            
            note_number <= MIDI_DATA_0;
        end

        if(MIDI_COMMAND[4]) TDM_VOICE_DATA <= sin_lut_output;
        else TDM_VOICE_DATA <= VOICE_OFF;
    end
endmodule



module simple_nco
#(
    parameter D_W = 16,
    parameter ADDR_W = 8
)
(
    input sys_clk,
    input nco_enable,
    input [(D_W - 1):0]nco_div,
    output reg [(ADDR_W - 1):0]nco_addr
);
    localparam RST_ADDR = {ADDR_W{1'b0}};

    reg [(D_W - 1):0]buffered_div;
    reg [(D_W - 1):0]nco_ctr;

    reg note_state;

    initial begin
        nco_addr = RST_ADDR;
        buffered_div = {D_W{1'b0}};
        nco_ctr = {D_W{1'b0}};

        note_state = 1'b0;
    end

    always @ (posedge sys_clk) begin
        
        /*
        nco_ctr <= nco_ctr + 1;
        
        if(nco_enable) begin
            //nco_ctr <= nco_ctr + 1;
            
            if(nco_ctr >= buffered_div) begin
                nco_addr <= nco_addr + 1;
                nco_ctr <= 16'h0000;
            end
            //else nco_ctr <= nco_ctr + 1;
        end
*/
        case (note_state)
            0: begin
                nco_ctr <= nco_ctr + 1;
                buffered_div <= nco_div;
                
                if(nco_ctr >= buffered_div) note_state <= 1'b1;
            end

            1: begin
                nco_ctr <= 16'h0000;
                nco_addr <= nco_addr + 1;
                note_state <= 1'b0;
            end
        endcase
    end
endmodule