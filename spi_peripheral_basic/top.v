module top
(
    input wire gpio_23,         // SCK
    input wire gpio_25,         // ~cs
    input wire gpio_26,         // MOSI
    output wire gpio_27,        // MISO
    output wire led_red,
    output wire led_green,
    output wire led_blue,

    output wire gpio_31,
    output wire gpio_37,
    output wire gpio_34,
    output wire gpio_43,
    
    output wire gpio_36,
    output wire gpio_42,
    output wire gpio_38,
    output wire gpio_28
);

    wire hfclk;               // Will be inferred to global clk
    SB_HFOSC inthfosc(
        .CLKHFEN(1'b1),     // enable output
        .CLKHFPU(1'b1),     // Turn on OSC
        .CLKHF(hfclk)
    );
    defparam inthfosc.CLKHF_DIV = "0b10";
    // 42M / 4 = 12M

    reg RLED, GLED, BLED;

    assign led_red = ~RLED;
    assign led_green = ~GLED;
    assign led_blue = ~BLED;

/*
module spi_hardip_top
#(
    parameter BYTE_W = 8
)
(
    input wire m_clk,
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
    wire spi_transfer_complete;

    reg [7:0]process_byte;
    wire [7:0]input_byte;


    assign gpio_31 = input_byte[7];
    assign gpio_37 = input_byte[6];
    assign gpio_34 = input_byte[5];
    assign gpio_43 = input_byte[4];
    assign gpio_36 = input_byte[3];
    assign gpio_42 = input_byte[2];
    assign gpio_38 = input_byte[1];
    assign gpio_28 = input_byte[0];


    spi_hardip_top SPIinst
    (
        .mosi_pad(gpio_26),
        .miso_pad(gpio_27),
        .sck_pad(gpio_23),
        .csn_pad(gpio_25),

        .DRDY(spi_transfer_complete),
        //.DWRITTEN(spi_data_write),
        .d_recieved(input_byte),
        .d_to_send(process_byte)
    );

    /*
module multi_spi
(
    input wire m_clk,
    input wire CSN,
    input wire SCK,
    input wire MOSI,
    output reg MISO,
    input wire [(D_W - 1):0]DATA_TO_SEND,
    output wire [(D_W - 1):0]DATA_RXD
    output reg DREADY;
);
    
    /*
    multi_spi mspi_test
    (
        .m_clk(hfclk),
        .CSN(gpio_25),
        .SCK(gpio_23),
        .MOSI(gpio_26),
        .MISO(gpio_27),
        .DATA_TO_SEND(process_byte),
        .DATA_RXD(input_byte),
        .DREADY(spi_transfer_complete)
    );
*/
    initial begin
        process_byte = 0;
       

        RLED = 1'b0;
        GLED = 1'b0;
        BLED = 1'b0;
    end

    always @ (posedge spi_transfer_complete) begin
        process_byte <= input_byte + 1;
        case (input_byte)
            1: RLED <= ~RLED;
            2: GLED <= ~GLED;
            3: BLED <= ~BLED;
        endcase
    end

 
  //  always @ (negedge gpio_25) RLED = ~RLED;
endmodule