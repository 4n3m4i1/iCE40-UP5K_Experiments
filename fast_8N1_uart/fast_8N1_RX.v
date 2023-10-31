



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

    // Setup Clock Parameters
    localparam CYC_PER_BIT      = SYSCLK_F / BAUDRATE;      // cycles per bit
    localparam START_BIT_OFFSET = 3 * (CYC_PER_BIT / 2);       // cycles to delay fall -> 50%
    localparam CLK_CT_BITS      = $clog2(START_BIT_OFFSET);

    // General Constants
    localparam LINE_HI      = 2'b11;
    localparam LINE_LO      = 2'b00;
    localparam RISING_EDGE  = 2'b01;
    localparam FALLING_EDGE = 2'b10;

    localparam FRAME_SIZE   = 8;

    localparam DATA_RDY     = 1'b1;
    localparam DATA_NRDY    = 1'b0;

    // States
    localparam IDLE         = 2'h0;
    localparam STALL_0      = 2'h1;
    localparam READ_DATA    = 2'h2;
    localparam PUBLISH      = 2'h3;

    // Registers
    reg [1:0]oa_state;
    reg [1:0]edge_detect;
    reg [3:0]shift_counter;
    reg [(CLK_CT_BITS - 1):0]cycle_ctr;
    reg [(FRAME_SIZE - 1):0]uarx_shift;

    initial begin
        oa_state        = IDLE;
        edge_detect     = LINE_LO;
        shift_counter   = 4'h0;
        cycle_ctr       = {(CLK_CT_BITS){1'b0}};
        uarx_shift      = {(FRAME_SIZE){1'b0}};
        DATA            = {(BYTE_W){1'b0}};

        DATA_RDY_STROBE = DATA_NRDY;
    end

    always @ (posedge sys_clk) begin
        case (oa_state)
            // 0: Wait for falling start
            IDLE: begin
                DATA_RDY_STROBE <= DATA_NRDY;
                if(en) begin
                    edge_detect     <= {edge_detect[0], RX_LINE};
                    
                    if(edge_detect == FALLING_EDGE) begin
                        oa_state    <= STALL_0;
                        cycle_ctr   <= {(CLK_CT_BITS){1'b0}};
                        shift_counter <= 4'h0;
                    end
                end
            end

            // 1: Stall and skip start bit
            STALL_0: begin
                if(cycle_ctr == START_BIT_OFFSET)begin
                    cycle_ctr   <= CYC_PER_BIT;
                    oa_state    <= READ_DATA;
                end
                else cycle_ctr  <= cycle_ctr + 1;
            end

            // 2: Read Data.. pretty much sums it up
            READ_DATA: begin
                if(cycle_ctr == CYC_PER_BIT) begin
                    cycle_ctr   <= {(CLK_CT_BITS){1'b0}};
                    uarx_shift  <= {RX_LINE, uarx_shift [(FRAME_SIZE - 1):1]};
                    shift_counter   <= shift_counter + 1;
                end
                else cycle_ctr  <= cycle_ctr + 1;

                if(shift_counter == FRAME_SIZE) begin
                    oa_state    <= PUBLISH;
                end
            end

            // 3: Publish data to system with the standard
            //  single cycle DATA READY strobe
            PUBLISH: begin
                DATA            <= uarx_shift[7:0];
                DATA_RDY_STROBE <= DATA_RDY;
                oa_state        <= IDLE;
            end
        endcase
    end
endmodule