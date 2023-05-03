/*
    Delaying of the ADC interface initiation is a must, 
    the power on sequence can happen wrong and the
    interface can start offset by 1 bit to the left.

    This is NOT accounted for here!!!!

    Do not implement with this enable sequence
*/

module top
(

    output led_red,

    input gpio_26,              // SDI
    output wire gpio_25,        // SDO
    output wire gpio_23,        // SCK
    output wire gpio_27,        // CSN

    // Debug LED Bar Graph
    output wire gpio_28,        // MSB
    output wire gpio_38,
    output wire gpio_42,
    output wire gpio_36,

    output wire gpio_43,
    output wire gpio_34,
    output wire gpio_37,
    output wire gpio_31         // LSB
);

    reg [7:0]dbg_div;

    assign gpio_28 = dbg_div[7];
    assign gpio_38 = dbg_div[6];
    assign gpio_42 = dbg_div[5];
    assign gpio_36 = dbg_div[4];
    assign gpio_43 = dbg_div[3];
    assign gpio_34 = dbg_div[2];
    assign gpio_37 = dbg_div[1];
    assign gpio_31 = dbg_div[0];

    wire clk_48M;           
    SB_HFOSC inthfosc
    (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_48M)
    );
    defparam inthfosc.CLKHF_DIV = "0b00";



// Pll @ 2x sck
    wire PLL_LOCK, PLL_OUT;
    reg clk_8M, clk_24M;
    // Internal PLL
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0010),
        .DIVF(7'b0111111),
        .DIVQ(3'b110),
        .FILTER_RANGE(3'b001)
    ) pll_uut (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PLLOUTCORE(PLL_OUT),
        .REFERENCECLK(clk_48M),
        .LOCK(PLL_LOCK)
    );


    assign gpio_23 = clk_8M;

    wire [7:0]adc_data;
    wire adc_done;

    ADCI_INTERFACE ADC01
    (
        .en(PLL_LOCK),
        .sys_clk(clk_24M),
        .ser_clk(clk_8M),

        .SDI(gpio_26),
        .CSN(gpio_27),
        .SDO(gpio_25),
        .DATA_READ(adc_data),
        .RX_DONE(adc_done)
    );


    wire [15:0]mag_val;
    wire mag_ready;
    dsp_goertzel_manager GMAN_0
    (
        .sys_clk(clk_24M),
        .adc_rdy(PLL_LOCK),
        .adc_data_ready(adc_done),
        .adc_data_in(adc_data),

        .goertzel_mag(mag_val),
        .mag_rdy(mag_ready)
    );


    reg [23:0]display_update_delay;
    reg which_byte_2_disp;

    reg [3:0]display_update_ctr;

    reg [15:0] temp_val;

    assign led_red = ~which_byte_2_disp;

    initial begin
        clk_8M = 1'b0;
        clk_24M = 1'b0;
        dbg_div = {8{1'b0}};
        which_byte_2_disp = 1'b0;
        display_update_delay = {23{1'b0}};
        display_update_ctr = 0;
    end

    always @ (posedge PLL_OUT) begin
        clk_8M <= ~clk_8M;
    end

    always @ (posedge clk_48M) begin
        clk_24M <= ~clk_24M;
    end

    always @ (posedge clk_24M) begin
        display_update_delay <= display_update_delay + 1;

/*
        if(display_update_delay == 0) begin             // Swap bytes every 0.5s
            which_byte_2_disp <= ~which_byte_2_disp;

            if(which_byte_2_disp) begin
                dbg_div <= temp_val[15:8];
            end
            else begin
                dbg_div <= temp_val[7:0];
            end
        end
*/
        if(mag_ready) begin                             // Update mag val every whatever s
            display_update_ctr <= display_update_ctr + 1;
            if(display_update_ctr == 0) begin
               // temp_val <= mag_val;
                dbg_div <= mag_val[15:0];
            end
        end
    end
endmodule