/*
    July/3/2023
    UART Testbench Instance Demonstrating
    how to integrate the fast_8N1_XX modules
    into a larger project.

*/

module top
(
    output wire gpio_23,        // tx
    input wire  gpio_25,        // rx
    
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


    wire clk_24M;           
    SB_HFOSC inthfosc
    (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_24M)
    );
    defparam inthfosc.CLKHF_DIV = "0b01";

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
    reg go;

    reg tx_load, tx_en;
    reg [7:0]tx_data;
    wire load_ok;
    fast_8N1_UART_TX transmitter
    (
        .sys_clk(clk_24M),
        .en(tx_en & go),
        .TX_LOAD(tx_load),
        .TX_DATA(tx_data),
        .LOAD_OK(load_ok),
        .TX_LINE(gpio_23)        
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
    wire [7:0]rx_data;
    wire rx_data_ready;
    fast_8N1_UART_RX receiver
    (
        .sys_clk(clk_24M),
        .en(tx_en),
        .RX_LINE(gpio_25),
        .DATA(rx_data),
        .DATA_RDY_STROBE(rx_data_ready)
    );




    reg [15:0]delayz;
    reg [4:0]ctt;
    reg [7:0]base;
    

    initial begin
        delayz  = 0;
        tx_data = 0;
        tx_en   = 0;
        tx_load = 0;
        ctt     = 0;
        base    = 8'h41;    // A
        dbg_div = 0;
        go      = 0;
    end

    always @ (posedge clk_24M) begin
        delayz <= delayz + 1;
        if(&delayz) begin
            tx_en <= 1'b1;
            if(load_ok) begin
                tx_load <= 1'b1;
                if(&ctt) tx_data <= 10;
                else tx_data <= base + ctt;
                ctt     <= ctt + 1;
            end
        end
        else begin
            tx_load <= 1'b0;
        end

        if(rx_data_ready) begin
            dbg_div <= rx_data;
            if(rx_data == 8'h53) go <= !go;
        end
    end

endmodule