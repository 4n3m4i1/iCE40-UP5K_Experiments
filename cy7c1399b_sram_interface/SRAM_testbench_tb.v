`timescale 1ns/1ns

module SRAM_testbench();

    reg sys_clk;

    reg en, wr, rd;

    reg [9:0]addr;
    reg [7:0]d_wr;
    wire [7:0]d_rd;

    wire dvalid;


    wire [7:0]SRAM_DATA;
    wire [9:0]SRAM_ADDR;
    wire OE, WE, CE;

    reg [7:0]t_data;

    assign SRAM_DATA = (WE) ? t_data : {8{1'bZ}};

    CY7C1399B_interface SRAM0
    (
        .enable(en),
        .sys_clk(sys_clk),
        .write_to_sram(wr),
        .read_from_sram(rd),
        .r_addr(addr),
        .w_addr(addr),
        .d_in(d_wr),
        .d_out(d_rd),
        .data_valid(dvalid),
        
        .SRAM_DATA(SRAM_DATA),
        .SRAM_ADDRESS(SRAM_ADDR),
        .SRAM_OE(OE),
        .SRAM_WE(WE),
        .SRAM_CE(CE)
    );

    initial begin
        t_data = 8'hC6;

        en = 0; wr = 0; rd = 0;
        addr = 10'h000;
        d_wr = 8'hAA;

        #50;
        en = 1;
        #100;
        addr = 10'h04C;
        wr = 1;
        #20;
        wr = 0;
        #200;
        addr = 10'h011;
        rd = 1;
        #20;
        rd = 0;

        #200;

        $finish;
    end



    initial begin
        $dumpfile("SRAM_testbench_tb.vcd");
        $dumpvars(0,SRAM_testbench);
    end

    initial begin       // FPGA clk
        sys_clk = 0;
        
        forever begin
            #10;
            sys_clk <= ~sys_clk;
        end
    end
endmodule;