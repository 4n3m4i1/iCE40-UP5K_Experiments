/*
    The ADC082S101 is a variable rate ADC that samples
    a single channel out of 2 at a rate of:

        Fs = SCK / 16

    Datasheet: https://www.ti.com/lit/ds/symlink/adc082s101.pdf?HQS=dis-dk-null-digikeymode-dsf-pf-null-wwe&ts=1682108694542&ref_url=https%253A%252F%252Fwww.ti.com%252Fgeneral%252Fdocs%252Fsuppproductinfo.tsp%253FdistId%253D10%2526gotoUrl%253Dhttps%253A%252F%252Fwww.ti.com%252Flit%252Fgpn%252Fadc082s101

    
    For this application the minimum rate of 500ksps has been selected so:

        500e3 = SCK / 16
        SCK = 8e6 Hz

    We will only sample from channel 0

    This instance is almost entirely aimed at continuous sampling
        at the predefined rate
*/



module ADCI_INTERFACE
#(
    parameter BYTE_W = 8,
    parameter SHIFT_IN_CT = 16
)
(
    input en,
    input sys_clk,
    input ser_clk,  
    
    input SDI,

    output reg CSN,
    output reg SDO,
    output reg [(BYTE_W - 1):0]DATA_READ,
    output reg RX_DONE
);
    localparam FALLING      = 2'b10;
    localparam RISING       = 2'b01;
    localparam NOEDGE       = 2'b00;

    localparam RX_VALID     = 1'b1;
    localparam RX_INVALID   = 1'b0;

    localparam CS_ASSERT    = 1'b0;
    localparam CS_DEASSERT  = 1'b1;

    localparam INIT         = 4'h0;
    localparam IDLE         = 4'h1;
    localparam INIT_ADC_RX  = 4'h2;
    localparam SHIFT_OUT    = 4'h3;
    localparam SHIFT_IN     = 4'h4;
    localparam IS_SHIFT_OVER = 4'h5;
    localparam SHIFT_DONE   = 4'h6;

    reg [1:0]edge_detect;
    reg [3:0]oa_state;
/*
    ADCCR
BIT     7   6   5   4   3   2   1   0
VAL     X   X   AD2 AD1 AD0 X   X   X

AD2 = X // For channel selection, see page 18 of datasheet
AD1 = 0
AD0 = 0

*/
    reg [(BYTE_W - 1):0]DO_FRAME;   // ADC Control Register
    reg [(SHIFT_IN_CT - 1):0]DI_FRAME;

    reg [3:0]shift_ctr;

    initial begin
        edge_detect = NOEDGE;

        CSN         = CS_DEASSERT;
        SDO         = 1'b0;

        DATA_READ   = {BYTE_W{1'b0}};
        RX_DONE     = RX_INVALID;

        oa_state    = IDLE;

        DO_FRAME    = {BYTE_W{1'b0}};
        DI_FRAME    = {SHIFT_IN_CT{1'b0}};
        shift_ctr   = 4'h0;
    end




    always @ (posedge sys_clk) begin
        edge_detect <= {edge_detect[0], ser_clk};

        case (oa_state)
// 0
            INIT: begin
                if(edge_detect == RISING && en) begin
                    oa_state <= INIT_ADC_RX;
                end
            end
// 1
            IDLE: begin
                if(en) begin
                    RX_DONE     <= RX_INVALID;
                    oa_state    <= INIT_ADC_RX;
                end
            end
// 2
            INIT_ADC_RX: begin
                if(en) begin
                    RX_DONE     <= RX_INVALID;
                    CSN         <= CS_ASSERT;
                    oa_state    <= SHIFT_OUT;
                    DO_FRAME    <= {BYTE_W{1'b0}};  // Select channel here
                    shift_ctr   <= 4'h0;
                end
            end
// 3
            SHIFT_OUT: begin
                if(edge_detect == FALLING) begin
                    SDO         <= DO_FRAME[(BYTE_W - 1)];             //Shift out  MSB First
                    DO_FRAME    <= {DO_FRAME[(BYTE_W - 2):0], 1'b0};   // ^
                    oa_state    <= SHIFT_IN;
                end
            end
// 4
            SHIFT_IN: begin
                if(edge_detect == RISING) begin
                    shift_ctr   <= shift_ctr + 1;
                    DI_FRAME    <= {DI_FRAME[(SHIFT_IN_CT - 2):0], SDI};
                    oa_state    <= IS_SHIFT_OVER;
                end
            end
// 5
            IS_SHIFT_OVER: begin
                if(shift_ctr == 4'h0) begin
                    // RX done
                    oa_state <= SHIFT_DONE;
                end
                else begin
                    // RX In progress
                    oa_state <= SHIFT_OUT;
                end
            end
// 6
            SHIFT_DONE: begin
                DATA_READ   <= DI_FRAME[10:3];  //
                RX_DONE     <= RX_VALID;
                oa_state    <= INIT_ADC_RX;
            end


        endcase
    end

endmodule