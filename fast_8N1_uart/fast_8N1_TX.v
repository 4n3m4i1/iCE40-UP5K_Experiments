

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

    // Setup Clock Parameters
    localparam CYC_PER_BIT      = SYSCLK_F / BAUDRATE;      // cycles per bit
    localparam CLK_CT_BITS      = $clog2(CYC_PER_BIT);


    // States
    localparam IDLE     = 2'h0;
    localparam TX_GO    = 2'h1;
    localparam CLEANUP  = 3'h3;

    // General Constants
    localparam FRAME_SIZE = BYTE_W + 2;

    reg [1:0]oa_state;
    reg [(FRAME_SIZE - 1):0]uatx_shift;
    reg [(CLK_CT_BITS - 1):0]cycle_ctr;

    initial begin
        oa_state    = IDLE;
        uatx_shift  = {(FRAME_SIZE){1'b0}};
        cycle_ctr   = {CLK_CT_BITS{1'b0}};
        TX_LINE     = 0;
        LOAD_OK     = 0;
        $display(CYC_PER_BIT);
        $display(CLK_CT_BITS);
    end


    always @ (posedge sys_clk) begin
        case (oa_state)
            // 0. Idle...
            IDLE: begin
                if(en && TX_LOAD) begin
                    // Assemble LSBit first frame
                    uatx_shift  <= {1'b1, TX_DATA[7:0], 1'b0};
                    cycle_ctr   <= (CYC_PER_BIT - 1);
                    oa_state    <= TX_GO;
                    LOAD_OK     <= 1'b0;
                end else begin
                    LOAD_OK     <= 1'b1;
                    TX_LINE     <= 1'b1;
                end
            end

            // 1. Transmit bits
            TX_GO: begin
                if(uatx_shift) begin
                    if(cycle_ctr == (CYC_PER_BIT - 1)) begin
                        TX_LINE     <= uatx_shift[0];
                        uatx_shift  <= uatx_shift >> 1;
                        cycle_ctr   <= {(CLK_CT_BITS){1'b0}};
                    end else cycle_ctr  <= cycle_ctr + 1;
                end else oa_state <= IDLE;
            end
        endcase
    end
endmodule