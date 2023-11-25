

module top
(
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

    reg [22:0]update_delay;

// Pll @ 2x sck
    wire PLL_LOCK, PLL_OUT;
    reg clk_8M;
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

    initial begin
        clk_8M      = 1'b0;
        dbg_div     = 8'h00;

        update_delay = {23{1'b0}};
    end

    // 8MHz ADC SPI clock for 500kHz sampling
    always @ (posedge PLL_OUT) begin
        clk_8M <= ~clk_8M; 
    end

    always @ (posedge clk_8M) begin
        update_delay <= update_delay + 1;

        if(update_delay == 0) begin
            dbg_div <= dbg_div + 1;
        end
    end


endmodule