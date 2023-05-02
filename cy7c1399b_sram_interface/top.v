module top
(
    output led_red,

    output gpio_6,      // SRAM_A_0
    output gpio_9,      // SRAM_A_1
    output gpio_10,     // SRAM_A_2
    output gpio_11,     // SRAM_A_3
    output gpio_12,     // SRAM_A_4
    output gpio_13,     // SRAM_A_5
    output gpio_18,     // SRAM_A_6
    output gpio_19,     // SRAM_A_7
    output gpio_20,     // SRAM_A_8
    output gpio_21,     // SRAM_A_9

    inout  gpio_44,     // SDAT_0
    inout  gpio_45,     // SDAT_1
    inout  gpio_46,     // SDAT_2
    inout  gpio_47,     // SDAT_3
    inout  gpio_48,     // SDAT_4
    inout  gpio_2,      // SDAT_5
    inout  gpio_3,      // SDAT_6
    inout  gpio_4,      // SDAT_7

    output gpio_43,     // SRAM CE
    output gpio_38,     // SRAM WE
    output gpio_42      // SRAM OE

);


    wire clk_24Mhz;             // Will be inferred to global clk
    SB_HFOSC inthfosc(
        .CLKHFEN(1'b1),     // enable output
        .CLKHFPU(1'b1),     // Turn on OSC
        .CLKHF(clk_24Mhz)
    );
    //defparam inthfosc.CLKHF_DIV = "0b01";
    // 48M / 2 = 24M
    defparam inthfosc.CLKHF_DIV = "0b01";



    wire [9:0]SRAM_ADDR_BUS;
    wire [7:0]SRAM_DATA_BUS;
    wire SRAM_OE, SRAM_WE, SRAM_CE;

    assign SRAM_OE = gpio_42;
    assign SRAM_WE = gpio_38;
    assign SRAM_CE = gpio_43;

    assign SRAM_DATA_BUS[0] = gpio_44;
    assign SRAM_DATA_BUS[1] = gpio_45;
    assign SRAM_DATA_BUS[2] = gpio_46;
    assign SRAM_DATA_BUS[3] = gpio_47;
    assign SRAM_DATA_BUS[4] = gpio_48;
    assign SRAM_DATA_BUS[5] = gpio_2;
    assign SRAM_DATA_BUS[6] = gpio_3;
    assign SRAM_DATA_BUS[7] = gpio_4;

    assign SRAM_ADDR_BUS[0] = gpio_6;
    assign SRAM_ADDR_BUS[1] = gpio_9;
    assign SRAM_ADDR_BUS[2] = gpio_10;
    assign SRAM_ADDR_BUS[3] = gpio_11;
    assign SRAM_ADDR_BUS[4] = gpio_12;
    assign SRAM_ADDR_BUS[5] = gpio_13;
    assign SRAM_ADDR_BUS[6] = gpio_18;
    assign SRAM_ADDR_BUS[7] = gpio_19;
    assign SRAM_ADDR_BUS[8] = gpio_20;
    assign SRAM_ADDR_BUS[9] = gpio_21;

    reg sram_en, sram_wr, sram_rd;
    reg [9:0]sram_addr;
    reg [7:0]sram_wr_data;
    wire [7:0]sram_rd_data;
    wire sram_data_ready;

    CY7C1399B_interface SRAM0
    (
        .enable(sram_en),
        .sys_clk(clk_24Mhz),
        .write_to_sram(sram_wr),
        .read_from_sram(sram_rd),
        .r_addr(sram_addr),
        .w_addr(sram_addr),
        .d_in(sram_wr_data),
        .d_out(sram_rd_data),
        .data_valid(sram_data_ready),

        .SRAM_DATA(SRAM_DATA_BUS),
        .SRAM_ADDRESS(SRAM_ADDR_BUS),
        .SRAM_OE(SRAM_OE),
        .SRAM_WE(SRAM_WE),
        .SRAM_CE(SRAM_CE)
    );

    reg [15:0]delay;

    assign led_red = (sram_rd_data > 24) ? 1'b0 : 1'b1;

    initial begin
        sram_addr = {10{1'b0}};
        sram_wr_data = {8{1'b0}};

        sram_en = 0;
        sram_wr = 0;
        sram_rd = 0;

        delay = {16{1'b0}};
    end

    always @ (posedge clk_24Mhz) begin
        delay <= delay + 1;

        if(delay > 16'h01FF) sram_en <= 1'b1;

        if(delay == 16'hF0AA) begin
            sram_wr_data <= sram_addr[8:1];
            sram_addr <= sram_addr + 1;
            sram_wr <= 1'b1;
        end

        if(delay == 16'hF0AB) sram_wr <= 1'b0;

    if(delay == 16'hFF00) sram_rd <= 1'b1;

    if(delay == 16'hFF01) sram_rd <= 1'b0;

    end


endmodule