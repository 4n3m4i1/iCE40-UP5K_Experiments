`timescale 1ns/1ps

module spi_module_tb();

/*
module spi_hardip_top
#(
    parameter BYTE_W = 8
)
(
    //input wire m_clk,
    input wire mosi_pad,
    input wire sck_pad,
    input wire csn_pad,
    output wire miso_pad,
    
    output reg DRDY,
    input wire DWRITTEN,

    output reg [(BYTE_W - 1):0]d_recieved,
    input wire [(BYTE_W - 1):0]d_to_send
);
*/

    reg sck, mosi, cs;
    wire miso, dready;

    reg [7:0]dts;
    wire [7:0]drx;

    spi_hardip_top spi_dut
    (
        .mosi_pad(mosi),
        .miso_pad(miso),
        .csn_pad(cs),
        .sck_pad(sck),
        .DRDY(dready),

        .d_recieved(drx),
        .d_to_send(drx)
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
        #2000;
        

        $finish;
    end

    initial
   
    begin
        $dumpfile("spi_module_tb.vcd");
        $dumpvars(0,spi_module_tb);
    end

    initial begin
        sck = 0;
        forever begin
            #10;
            sck = ~sck;
        end
    end
endmodule