`timescale 1ns/1ps

module spi_single_clk_tb();

    reg sys_clk;
    reg sck, mosi, cs;
    wire miso, dready;

    reg [7:0]dts;
    wire [7:0]drx;

/*
module spi_single_clk
#(
    parameter BYTE_W = 8
)
(
    input sys_clk,

    input csn_pad,
    input sck_pad,
    input mosi_pad,
    output wire miso_pad,

    input spi_data_written,
    input [(BYTE_W - 1):0]spi_data_to_send,
    output reg [(BYTE_W - 1):0]spi_data_rx,
    output reg spi_dreq
);
*/
    spi_single_clk SIN_inst
    (
        .sys_clk(sys_clk),
        .csn_pad(cs),
        .sck_pad(sck),
        .mosi_pad(mosi),
        .miso_pad(miso),
        .spi_dreq(dready),

        .spi_data_written(dready),

        .spi_data_to_send(dts),
        .spi_data_rx(drx)
    );

initial begin
        mosi = 0;
        cs = 1;
    
        dts = 0;

        #45;
        cs = 0;
        mosi = 1;
/*
        #20;
        mosi = 0;
        #20;
        mosi = 1;
        #20;
        mosi = 0;
        #20;
        mosi = 0;
        #20;
        mosi = 1;
        #20;
        mosi = 0;
        #20;
        mosi = 0;
        #20;
        mosi = 1;
        #20;
        mosi = 0;
        #20;
        mosi = 0;
        #20;
        mosi = 1;
        #20;
        mosi = 0;
        #20;
        mosi = 0;
        #20;
        mosi = 1;
        #20;
        mosi = 0;
*/
        #20000000;
        

        $finish;
    end

    initial
   
    begin
        $dumpfile("spi_single_domain_tb.vcd");
        $dumpvars(0,spi_single_clk_tb);
    end

    initial begin
        sck = 0;
        forever begin
            #120;
            sck <= ~sck;
        end
    end

    initial begin
        sys_clk = 0;
        forever begin
            #10;
            sys_clk <= ~sys_clk;
        end
    end
endmodule