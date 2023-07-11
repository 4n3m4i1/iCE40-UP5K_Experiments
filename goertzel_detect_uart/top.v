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

    output wire gpio_32,        // UATX

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


    wire [15:0]mag_val_0, mag_val_1;
    wire mag_ready;
    wire [4:0]current_run;

    parallel_goertzel PGS0
    (
        .sys_clk(clk_24M),
        .adc_ready(PLL_LOCK),
        .adc_data_rdy(adc_done),
        .adc_data(adc_data),
        .G0(mag_val_0),
        .G1(mag_val_1),
        .G_READY(mag_ready),
        .current_run(current_run)
    );



    // Uart interface
    reg [7:0]uart0_tx;
    reg uart0_tx_loaded;
    wire uart0_okay_to_load;
    
    reg [3:0]send_states;
    reg start_sending_uatx;

    localparam WAIT         = 4'h0;
    localparam SEND_CURR_RUN = 4'h1;
    localparam WFS_CURR_RUN = 4'h2;
    localparam SEND_COMMA   = 4'h3;
    localparam WFS_COMMA    = 4'h4;
    localparam SEND_0_LSB   = 4'h5;
    localparam WFS_0_LSB    = 4'h6;
    localparam SEND_0_MSB   = 4'h7;
    localparam WFS_0_MSB    = 4'h8;
    localparam SEND_COMMA_0 = 4'h9;
    localparam WFS_COMMA_0  = 4'hA;
    localparam SEND_1_LSB   = 4'hB;
    localparam WFS_1_LSB    = 4'hC;
    localparam SEND_1_MSB   = 4'hD;
    localparam WFS_1_MSB    = 4'hE;
    localparam SEND_TERM    = 4'hF;

    localparam COMMA        = 8'h2C;
    localparam TERM         = 8'h0A;

    uart_controller UART0
    (
        .enable(PLL_LOCK),
        .sys_clk(clk_24M),

        //.RX_LINE(),               // Unused RX
        //.RX_DATA(),
        //.RX_DATA_READY(),

        .TX_DATA(uart0_tx),
        .TX_LOAD(uart0_tx_loaded),
        .TX_LOAD_OKAY(uart0_okay_to_load),
        .TX_LINE(gpio_32)
    );

    reg [23:0]display_update_delay;
    reg which_byte_2_disp;

    reg [3:0]display_update_ctr;

    reg [15:0] temp_val_0,  temp_val_1;

    assign led_red = ~which_byte_2_disp;

    initial begin
        clk_8M = 1'b0;
        clk_24M = 1'b0;
        dbg_div = {8{1'b0}};
        which_byte_2_disp = 1'b0;
        display_update_delay = {23{1'b0}};
        display_update_ctr = 0;

        uart0_tx = 0;
        uart0_tx_loaded = 0;
        send_states = 0;

        temp_val_0 = 0;
        temp_val_1 = 0;
        start_sending_uatx = 0;
    end

    always @ (posedge PLL_OUT) begin
        clk_8M <= ~clk_8M;
    end

    always @ (posedge clk_48M) begin
        clk_24M <= ~clk_24M;
    end

    always @ (posedge clk_24M) begin
        if(mag_ready) begin                             // Update mag val every whatever s
            temp_val_0 <= mag_val_0;
            temp_val_1 <= mag_val_1;
            //dbg_div     <= mag_val_0[7:0];
            if(send_states == WAIT) start_sending_uatx <= 1'b1;
        end

        if(start_sending_uatx) start_sending_uatx <= 1'b0;
    end

    always @ (posedge clk_24M) begin
        case (send_states)
            WAIT: begin
                uart0_tx_loaded <= 1'b0;
                if(start_sending_uatx) send_states <= send_states + 1;
            end

            SEND_CURR_RUN: begin
                uart0_tx    <= {3'b000, current_run[4:0]};
                uart0_tx_loaded <= 1'b1;
                send_states <= send_states + 1;
            end

            WFS_CURR_RUN: begin
                uart0_tx_loaded <= 1'b0;
                if(uart0_okay_to_load) send_states <= send_states + 1;
            end

            SEND_COMMA: begin
                uart0_tx    <= COMMA;
                uart0_tx_loaded <= 1'b1;
                send_states <= send_states + 1;
            end

            WFS_COMMA: begin
                uart0_tx_loaded <= 1'b0;
                if(uart0_okay_to_load) send_states <= send_states + 1;
            end

            SEND_0_LSB: begin
                uart0_tx    <= mag_val_0[7:0];
                uart0_tx_loaded <= 1'b1;
                send_states <= send_states + 1;
            end

            WFS_0_LSB: begin
                uart0_tx_loaded <= 1'b0;
                if(uart0_okay_to_load) send_states <= send_states + 1;
            end

            SEND_0_MSB: begin
                uart0_tx    <= mag_val_0[15:8];
                uart0_tx_loaded <= 1'b1;
                send_states <= send_states + 1;
            end

            WFS_0_MSB: begin
                uart0_tx_loaded <= 1'b0;
                if(uart0_okay_to_load) send_states <= send_states + 1;
            end

            SEND_COMMA_0: begin
                uart0_tx    <= COMMA;
                uart0_tx_loaded <= 1'b1;
                send_states <= send_states + 1;
            end

            WFS_COMMA_0: begin
                uart0_tx_loaded <= 1'b0;
                if(uart0_okay_to_load) send_states <= send_states + 1;
            end

            SEND_1_LSB: begin
                uart0_tx    <= mag_val_1[7:0];
                uart0_tx_loaded <= 1'b1;
                send_states <= send_states + 1;
            end

            WFS_1_LSB: begin
                uart0_tx_loaded <= 1'b0;
                if(uart0_okay_to_load) send_states <= send_states + 1;
            end

            SEND_1_MSB: begin
                uart0_tx    <= mag_val_1[15:8];
                uart0_tx_loaded <= 1'b1;
                send_states <= send_states + 1;
            end

            WFS_1_MSB: begin
                uart0_tx_loaded <= 1'b0;
                if(uart0_okay_to_load) send_states <= send_states + 1;
            end

            SEND_TERM: begin
                uart0_tx    <= TERM;
                uart0_tx_loaded <= 1'b1;
                send_states <= WAIT;
            end
        endcase
    end
endmodule