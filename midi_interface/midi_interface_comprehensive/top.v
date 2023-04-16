

module midi_test_implementation
(
    input wire gpio_26,


    output wire gpio_3,
 //   output wire gpio_4,
  //  output wire gpio_44,
   // output wire gpio_6

    // Debug LED
    output wire gpio_28,
    output wire gpio_38,
    output wire gpio_42,
    output wire gpio_36,

    output wire gpio_43,
    output wire gpio_34,
    output wire gpio_37,
    output wire gpio_31

);

/*
    reg [7:0]rxd_byte;

    assign gpio_28 = rxd_byte[7];
    assign gpio_38 = rxd_byte[6];
    assign gpio_42 = rxd_byte[5];
    assign gpio_36 = rxd_byte[4];
    assign gpio_43 = rxd_byte[3];
    assign gpio_34 = rxd_byte[2];
    assign gpio_37 = rxd_byte[1];
    assign gpio_31 = rxd_byte[0];
*/

    wire clk_48M;
    SB_HFOSC inthfosc
    (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_48M)
    );
    defparam inthfosc.CLKHF_DIV = "0b00";




    wire [15:0]ddsdat_0;

    wire [7:0]dbg_div;
 //   wire enable_0;

    assign gpio_28 = dbg_div[7];
    assign gpio_38 = dbg_div[6];
    assign gpio_42 = dbg_div[5];
    assign gpio_36 = dbg_div[4];
    assign gpio_43 = dbg_div[3];
    assign gpio_34 = dbg_div[2];
    assign gpio_37 = dbg_div[1];
    assign gpio_31 = dbg_div[0];


/*
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
    output reg TDM_CHAN_ENABLED
);
*/
    MIDI_2 m2o
    (
        .sys_clk(clk_48M),
        .MIDI_DIN(gpio_26),
        .TDM_VOICE_DATA(ddsdat_0),
        .curr_div(dbg_div)
    );

    // Outputs for testing
    fods_mod mod_0
    (
        .mod_clk(clk_48M),
        .mod_din(ddsdat_0),
        .mod_dout(gpio_3)
    );


endmodule