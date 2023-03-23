module top
#(
    parameter BYTE_W = 8
)
(
    input wire gpio_23,         // SCK
    input wire gpio_25,         // ~cs
    input wire gpio_26,         // MOSI
    output wire gpio_27,        // MISO
    output wire gpio_2          // Clk out
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

    reg [8:0]ckctr;

    reg ckos8;

    assign gpio_2 = (PLL_LOCK) ? ckos8 : 1'b0;

/*
module spi_top
#(
    parameter BYTE_W = 8
)
(
    input wire mosi_pad,
    input wire sck_pad,
    input wire csn_pad,
    output wire miso_pad,
    
    output reg DRDY,

    output reg [(BYTE_W - 1):0]d_recieved,
    input wire [(BYTE_W - 1):0]d_to_send
);
*/
    // Mode 0, MSB first, SCK driven

    wire data_ready_strobe;
    reg [(BYTE_W - 1):0] TX_DATA;
    wire [(BYTE_W - 1):0] RX_DATA;

    spi_top spi_inst_0
    (
        .sck_pad(gpio_23),
        .csn_pad(gpio_25),
        .mosi_pad(gpio_26),
        .miso_pad(gpio_27),
        .DRDY(data_ready_strobe),
        .d_recieved(RX_DATA),
        .d_to_send(TX_DATA)
    );

    initial begin
        ckctr = 0;
        TX_DATA = 0;
        ckos8 = 0;
    end

    always @ (posedge clk_100mhz) begin
        ckctr = ckctr + 1;
        if(ckctr >= RX_DATA) begin
            ckos8 = ~ckos8;
            ckctr = 0;
        end
    end

endmodule