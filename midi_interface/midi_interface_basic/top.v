


module top_basic_midi
(
    input gpio_26,

    output wire gpio_28,
    output wire gpio_38,
    output wire gpio_42,
    output wire gpio_36,

    output wire gpio_43,
    output wire gpio_34,
    output wire gpio_37,
    output wire gpio_31,

    output wire led_green
);

    reg [7:0]rxd_byte;
    reg data_byte_read;

    assign led_green = data_byte_read;

    assign gpio_28 = rxd_byte[7];
    assign gpio_38 = rxd_byte[6];
    assign gpio_42 = rxd_byte[5];
    assign gpio_36 = rxd_byte[4];
    assign gpio_43 = rxd_byte[3];
    assign gpio_34 = rxd_byte[2];
    assign gpio_37 = rxd_byte[1];
    assign gpio_31 = rxd_byte[0];


    wire clk_48M;
    SB_HFOSC inthfosc
    (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_48M)
    );
    defparam inthfosc.CLKHF_DIV = "0b00";


/*
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
*/
    wire [7:0]data_ingest;
 
    wire bytes_ready, is_commd;
    single_midi_in midiin
    (
        .sys_clk(clk_48M),
        .MIDI_IN(gpio_26),
        .data_rx(data_ingest),
        .is_command(is_commd),
        .new_byte_strobe(bytes_ready)
    );

    

   

    initial begin
        data_byte_read <= 1'b0;
        rxd_byte = 8'h00;
    end

    always @ (posedge clk_48M) begin
        if(bytes_ready) begin
            
            if(is_commd) begin
                data_byte_read <= 1'b1;
                rxd_byte <= data_ingest;
            end
        end
    end
endmodule