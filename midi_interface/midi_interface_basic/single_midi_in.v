

module single_midi_in
#(
    parameter BYTE_W = 8,               // std byte w
    parameter MIDI_BAUD = 31250,        // 31k250 std midi baud
    parameter MIDI_FRAME_SIZE = 10,     // 8N1 format
    parameter SYSCLK_F = 48000000       // 48M from hfosc
)
(
    input sys_clk,
    input MIDI_IN,

    output reg [(BYTE_W - 1):0] data_rx,
    output reg is_command,
    output reg new_byte_strobe
);

    // Should be 768
    //localparam CLK_PER_MIDI_BIT = (SYSCLK_F / MIDI_BAUD) / 2;
    localparam CLK_PER_MIDI_BIT = 11'd768;


    // 384
    //localparam HALF_BIT_PERIOD = CLK_PER_MIDI_BIT / 2;
    localparam HALF_BIT_PERIOD = 11'd384;

    // Falling edge for start bit
    localparam START_CONDITION = 2'b10;

    reg [2:0]state;
    reg [10:0]clk_accumulator;
    reg [1:0]start_bit_detector;
    reg [9:0]frame_input;

    initial begin
        state = 3'b000;
        data_rx = 8'h00;
        is_command = 1'b0;
        start_bit_detector = 2'b00;
        clk_accumulator = {11{1'b0}};
        frame_input = {10{1'b0}};
        new_byte_strobe = 1'b0;
    end

/*
    X---\___/---\___/---\___/---\___/---\___/---\___/
    |   |   |   |   |   |   |   |   |   |   |   |   |
        ST

*/
    // Start detector, "Baud rate generator"
    always @ (posedge sys_clk) begin
        start_bit_detector <= {start_bit_detector[0], MIDI_IN};
        

        if((~|state) && start_bit_detector == START_CONDITION) begin
            state <= 3'b001;
            clk_accumulator <= {11{1'b0}};
        end
        //else begin
        //    clk_accumulator <= clk_accumulator + 1;
        //end

        // Main state machine
        case (state)
            1: begin    // Stall for first 1.5 half periods
                if(clk_accumulator >= (HALF_BIT_PERIOD + CLK_PER_MIDI_BIT)) begin
                    clk_accumulator <= {11{1'b0}};
                    state <= state + 1;
                    frame_input <= {MIDI_IN, 1'b1, 8'b00000000};
                end
                else begin
                    clk_accumulator <= clk_accumulator + 1;
                end
            end

            2: begin    // Read bits
                if(clk_accumulator >= (CLK_PER_MIDI_BIT)) begin
                    clk_accumulator <= {11{1'b0}};
                    frame_input <= {MIDI_IN, frame_input[9:1]};
                end
                else begin
                    clk_accumulator <= clk_accumulator + 1;
                end

                if(frame_input[0]) state <= state + 1;
            end

            3: begin
                clk_accumulator <= {11{1'b0}};
                state <= state + 1;

                data_rx <= frame_input[8:1];
                new_byte_strobe <= 1'b1;

                is_command <= frame_input[8]; 
            end

            4: state <= state + 1;

            5: begin
                new_byte_strobe <= 1'b0;
            end

        endcase
    end
endmodule