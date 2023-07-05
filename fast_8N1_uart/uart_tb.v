`timescale 1ns/1ps

module uart_tb();

    reg sys_clk;
    wire TX, LOAD_TO_SEND;
    reg RX, enable, tx_load;

/*
module fast_8N1_UART_TX
#(
    parameter SYSCLK_F = 24000000,
    parameter BYTE_W = 8,
    parameter BAUDRATE = 500000
)
(
    input sys_clk,
    //input rst,
    input en,

    input TX_LOAD,
    input [(BYTE_W - 1):0]TX_DATA,

    output reg LOAD_OK,

    output reg TX_LINE
);
*/
    reg [7:0]tx_data;
    fast_8N1_UART_TX transmitter
    (
        .sys_clk(sys_clk),
        .en(enable),
        .TX_LOAD(tx_load),
        .TX_DATA(tx_data),
        .LOAD_OK(LOAD_TO_SEND),
        .TX_LINE(TX)
    );

/*
module fast_8N1_UART_RX
#(
    parameter SYSCLK_F = 24000000,
    parameter BYTE_W = 8,
    parameter BAUDRATE = 500000
)
(
    input sys_clk,
    //input rst,
    input en,

    input RX_LINE,

    output reg [(BYTE_W - 1):0]DATA,

    output reg DATA_RDY_STROBE
);
*/
    initial begin
        enable = 0;
        RX = 0;
        tx_load = 0;
        tx_data = 8'hA5;
        #20;
        enable = 1;
        tx_load = 1;
        #20;
        tx_load = 0;
        #80000;
        tx_data = 8'h81;
        tx_load = 1;
        #20;
        tx_load = 0;
        #80000;

        $finish;
    end

    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0,uart_tb);
    end

    initial begin       // 48MHz standin
        sys_clk = 0;
        forever begin
            #10;
            sys_clk <= ~sys_clk;
        end
    end
endmodule