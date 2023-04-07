/*
    Single clock domain SPI peripheral

*/
module top
#(
    parameter BYTE_W = 8
)
(
    input wire gpio_23,         // SCK
    input wire gpio_25,         // ~cs
    input wire gpio_26,         // MOSI
    output wire gpio_27,        // MISO

    output wire led_green
    //output wire led_blue
);
//    wire dsp_done;
//    assign led_blue = dsp_done;

    wire clk_24Mhz;             // Will be inferred to global clk
    SB_HFOSC inthfosc(
        .CLKHFEN(1'b1),     // enable output
        .CLKHFPU(1'b1),     // Turn on OSC
        .CLKHF(clk_24Mhz)
    );
    //defparam inthfosc.CLKHF_DIV = "0b01";
    // 42M / 2 = 24M
    defparam inthfosc.CLKHF_DIV = "0b00";

/*
module main_state_machine
#(
    parameter BYTE_W = 8
)
(
    input sys_clk,
    input CSN_PAD,
    input SCK_PAD,
    input MOSI_PAD,
    output wire MISO_PAD,


    output reg [(BYTE_W - 1):0]SYSCFG,
    output reg [(BYTE_W - 1):0]COMMCFG,

    input [(BYTE_W - 1):0]COMM_RX_FIFO_COUNT,
    input [(BYTE_W - 1):0]COMM_TX_FIFO_COUNT
);
*/

    wire [15:0]mul_res;

    main_state_machine MSM_0
    (
        .sys_clk(clk_24Mhz),
        .CSN_PAD(gpio_25),
        .SCK_PAD(gpio_23),
        .MOSI_PAD(gpio_26),
        .MISO_PAD(gpio_27),

        .comm_is_RX(1'b0),
        .comm_is_TX(1'b1),

        //.COMM_RX_FIFO_COUNT(8'hAA),
        //.COMM_TX_FIFO_COUNT(8'h43)

        .COMM_RX_FIFO_COUNT(mul_res[15:8]), // 0x05
        .COMM_TX_FIFO_COUNT(mul_res[7:0])   // 0x07
    );


// TESTING MULTIPLIER
/*
module dsp_16x16_fix14_16_signed_mul
#(
    parameter D_W = 16
)
(
    input sys_clk,
    input dsp_CE,
    input [(D_W - 1):0]dsp_A,
    input [(D_W - 1):0]dsp_B,
    output [(D_W - 1):0]fix_14_16_Out
);
*/
/*
    dsp_16x16_fix14_16_signed_mul MUL0
    (
        .sys_clk(clk_24Mhz),
        .dsp_CE(1'b1),
        .dsp_A(16'h2826),
        .dsp_B(16'h012B),
        .fix_14_16_Out(mul_res)
    );
*/
/*
module dsp_16x16_fix14_16_signed_mac
#(
    parameter D_W = 16
)
(
    input sys_clk,
    input dsp_CE,
    input [(D_W - 1):0]dsp_A,
    input [(D_W - 1):0]dsp_B,
    input [(D_W - 1):0]dsp_C,
    input [(D_W - 1):0]dsp_D,
    output [(D_W - 1):0]fix_14_16_Out
);
*/

/*
    reg [15:0]MUL_ADD_0;

    dsp_16x16_fix14_16_signed_mac MUL0
    (
        .sys_clk(clk_24Mhz),
        .dsp_CE(1'b1),
        .dsp_A(16'h0214),
        .dsp_B(16'h0222),
        .dsp_C({2'b00, MUL_ADD_0[15:2]}),       // Apply shift to added term
        .dsp_D({MUL_ADD_0[1:0], {14{1'b0}}}),   // Apply shift to added term
        .fix_14_16_Out(mul_res)
    );

    initial begin
        MUL_ADD_0 = 16'h0012;
    end
*/
/*
module dsp_control_unit
#(
    parameter BYTE_W = 8,
    parameter D_W = 16
)
(
    input sys_clk,
    input dsp_en,
/*
    input ADC_MISO,
    output wire ADC_MOSI,
    output wire ADC_CS,
    output wire ADC_SCK,

    output reg [7:0]result_byte,
    output reg result_ready_strobe,

    output reg isRX,                 // Has DSP detected a transmission is ongoing

    input [(BYTE_W - 1):0]input_data,
    input TX_requested,             // High when TX fifo has data
    output reg new_input_request    // request new TX fifo data
*//*
    output wire [15:0]goert_data
);
*/

/*
    dsp_control_unit DSP_CU_0
    (
        .sys_clk(clk_24Mhz),
        .goert_data(mul_res),
        .goert_indic(dsp_done)
    );
*/

/*
module goertzel_inner_pipelined_loop_component
(
    input dsp_clk,
    input signed [15:0]coeff,
    input signed [15:0]t1,
    input signed [15:0]t2,
    input signed [15:0]data,

    output signed [15:0]t1_out
);
*/

/*
    parameter T_COEFF   = 16'h2826;
    parameter T_T1      = 16'hFEC7;
    parameter T_T2      = 16'h1882;
    parameter T_DATA    = 16'h0005;

    goertzel_inner_pipelined_loop_component GINCOM
    (
        .dsp_clk(clk_24Mhz),
        .coeff(T_COEFF),
        .t1(T_T1),
        .t2(T_T2),
        .data(T_DATA),

        .t1_out(mul_res)
    );
*/

/*
module t_goert_runtime
(
    input system_clk,
    //input runme, 

    output reg [15:0]result
);
*/
    assign led_green = (mul_res == 16'h7A63) ? 1'b0 : 1'b1;

    t_goert_runtime TGT
    (
        .system_clk(clk_24Mhz),
        .result(mul_res)  
    );


endmodule