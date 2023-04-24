

module top
(
    // ADC SPI Interface
    input gpio_26,              // SDI
    output wire gpio_25,        // SDO
    output wire gpio_23,        // SCK
    output wire gpio_27,        // CSN


    // MCU SPI Interface

    output wire gpio_32,        // dbg bank change

    output wire led_red,

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

    // ADC SPI SCK
    assign gpio_23 = clk_8M;

    wire [7:0]adc_data;
    wire adc_done;
    ADCI_INTERFACE ADC0
    (
        .en(PLL_LOCK),
        .sys_clk(clk_48M),
        .ser_clk(clk_8M),

        .SDI(gpio_26),
        .CSN(gpio_27),
        .SDO(gpio_25),
        .DATA_READ(adc_data),
        .RX_DONE(adc_done)
    );



    wire sample_bank_val;
    wire [7:0]rd_dat;
    reg  [15:0]update_delay;
    wire [8:0]rd_adr;

    sample_fifo SFO1
    (
        .en(PLL_LOCK),
        .sys_clk(clk_48M),
        .input_data_rdy(adc_done),
        .input_data(adc_data),
        .read_address(rd_adr),
        .read_data(rd_dat),
        .current_bank(sample_bank_val)
    );

    reg [15:0]last_read_mag;
    wire [15:0]magnitude_result;
    wire magnitude_ready;
    goertzel_top_v3 GTV03
    (
        .sys_clk(clk_48M),
        .bank_switch(sample_bank_val),
        .bank_addr(rd_adr),
        .bank_data(rd_dat),
        .goertzel_done(magnitude_ready),
        .goertzel_mag(magnitude_result)
    );

    assign gpio_32 = sample_bank_val;

    reg MSB_LSB;
    assign led_red = ~MSB_LSB;

    initial begin
        clk_8M      = 1'b0;
        dbg_div     = 8'h00;

        update_delay = {16{1'b0}};

        MSB_LSB = 1'b0;
    end

    // 8MHz ADC SPI clock for 500kHz sampling
    always @ (posedge PLL_OUT) begin
        clk_8M <= ~clk_8M; 
    end

    always @ (posedge clk_8M) begin
        update_delay <= update_delay + 1;

        if(update_delay == 16'h0000) begin
            MSB_LSB <= ~MSB_LSB;

            // print 16 bit magnitude results
            if(MSB_LSB) begin
                dbg_div <= last_read_mag[15:8];
            end else begin
                dbg_div <= last_read_mag[7:0];
            end
        end

        if(magnitude_ready) begin
            last_read_mag <= magnitude_result;
        end
    end


endmodule