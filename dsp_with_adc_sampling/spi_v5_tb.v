

module spi_v5_testbench();






/*
module spi_peripheral_v5
#(
    parameter BYTE_W = 8
)
(
    input sys_clk,

    input [(BYTE_W - 1):0]D_TO_SEND;

    input CSN_PAD,
    input SCK_PAD,
    input MOSI_PAD,

    output reg MISO_PAD,

    output reg RX_DONE,
    output reg [(BYTE_W - 1):0]RX_DATA
);
*/
    reg MOSI, sck, sys_clk, csn;
    reg [7:0]d_to_send;

    wire MISO, RXDONE;
    wire [7:0]RXDAT;
    spi_peripheral_v5 SPI5
    (
        .sys_clk(sys_clk),
        .D_TO_SEND(d_to_send),
        .CSN_PAD(csn),
        .SCK_PAD(sck),
        .MOSI_PAD(MOSI),
        .MISO_PAD(MISO),
        .RX_DONE(RXDONE),
        .RX_DATA(RXDAT)
    );

    initial begin
        MOSI = 1'b0;
        csn = 1'b1;
        //d_to_send = 8'b10100101;
        d_to_send = 8'h80;

        #150;
        csn = 1'b0;


        #200000;

        $finish;
    end

    initial begin
        $dumpfile("spi_v5_tb.vcd");
        $dumpvars(0,spi_v5_testbench);
    end

    initial begin       // 8MHz standin
        sck = 0;
        forever begin
            #60;
            sck <= ~sck;
        end
    end

    initial begin       // 48MHz standin
        sys_clk = 0;
        forever begin
            #10;
            sys_clk <= ~sys_clk;
        end
    end
endmodule