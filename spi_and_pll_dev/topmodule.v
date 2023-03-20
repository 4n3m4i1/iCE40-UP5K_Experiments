module top
#(
    parameter BYTE_W = 8
)
(
    output wire gpio_31
);

    wire clk_48mhz, clk_100mhz;

    // Internal 48MHz osc
    SB_HFOSC SB_HFOSC_inst(
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_48mhz)
    );

/*
    icepll -i 48 -o 100
    Feedback:   Simple
    F_PFD       16.000 MHz
    F_VCO       800.00 MHz

    In:         48.00 MHz
    Out:        100.00 MHz (achieved)

    DIVR        2 (4'b0010)
    DIVF        49 (7'b0110001)
    DIVQ        3 (3'b011)

    Filter Range    1 (3'b001)
*/

    wire PLL_LOCK;

    // Internal PLL
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0010),
        .DIVF(7'b0110001),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
    ) pll_uut (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PLLOUTCORE(clk_100mhz),
        .REFERENCECLK(clk_48mhz),
        .LOCK(PLL_LOCK)
    );

    reg [3:0]cks8;

    assign gpio_31 = (PLL_LOCK) ? cks8[0] : 1'b0;

    initial begin
        cks8 = 0;
    end

    always @ (posedge clk_100mhz) cks8 <= cks8 + 1;

endmodule