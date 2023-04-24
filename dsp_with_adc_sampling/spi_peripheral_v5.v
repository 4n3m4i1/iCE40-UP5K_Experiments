/*
    SPI Peripheral Module V5, now with more states!

    Mode 0 hardcoded peripheral, 8 bits, MSB first
*/

module spi_peripheral_v5
#(
    parameter BYTE_W = 8
)
(
    input sys_clk,

    input [(BYTE_W - 1):0]D_TO_SEND,

    input CSN_PAD,
    input SCK_PAD,
    input MOSI_PAD,

    output reg MISO_PAD,

    output reg RX_DONE,
    output reg [(BYTE_W - 1):0]RX_DATA
);

    localparam INIT     = 0;
    localparam IDLE     = 1;
    localparam SHIFT_IN = 2;
    localparam SHIFT_OUT= 3;
    localparam CLEANUP  = 4;
    localparam INITIAL_SHIFT = 5;
    localparam CLEARFLAGS   = 6;

    reg [1:0]sck_edge;
    localparam SCK_FALLING  = 2'b10;    // Mode 0 Shift Out
    localparam SCK_RISING   = 2'b01;    // Mode 0 Shift In
    localparam SCK_NO_EDGE  = 2'b00;    // Mode 0 clock idle low

    reg [(BYTE_W - 1):0]d_shift_in;
    reg [(BYTE_W - 1):0]d_shift_out;

    reg [3:0]oa_state;

    reg MOSI_PAD_BUFFER;
    reg [2:0]shift_ctr;

    initial begin
        oa_state    = 3'b000;

        sck_edge    = SCK_NO_EDGE;

        d_shift_in  = {(BYTE_W){1'b0}};
        d_shift_out = {(BYTE_W){1'b0}};

        MOSI_PAD_BUFFER = 1'b0;
        MISO_PAD    = 1'b0;
        RX_DONE     = 1'b0;
        RX_DATA     = {(BYTE_W){1'b0}};
        shift_ctr   = 3'h0;
    end

    always @ (posedge sys_clk) begin
        sck_edge        <= {sck_edge[0], SCK_PAD};
        MOSI_PAD_BUFFER <= MOSI_PAD;

        case (oa_state)
            INIT: begin
                oa_state <= IDLE;
            end

            IDLE: begin
                RX_DONE <= 1'b0;
                if(!CSN_PAD) begin
                    sck_edge <= SCK_NO_EDGE;
                    oa_state <= INITIAL_SHIFT;
                    d_shift_out <= D_TO_SEND;
                end
            end

            SHIFT_IN: begin
                if(sck_edge == SCK_RISING) begin
                    d_shift_in  <= {d_shift_in[(BYTE_W - 2):0], MOSI_PAD_BUFFER};
                    oa_state    <= SHIFT_OUT;
                end
            end

            SHIFT_OUT: begin
                if(sck_edge == SCK_FALLING) begin
                    MISO_PAD    <= d_shift_out[BYTE_W - 1];
                    d_shift_out <= {d_shift_out[(BYTE_W - 2):0], 1'b0};
                    shift_ctr   <= shift_ctr + 1;

                    if(shift_ctr == 3'b111) oa_state <= CLEANUP;
                    else oa_state <= SHIFT_IN;
                end
            end

            CLEANUP: begin  // Byte transmission/recieve cycle over
                RX_DONE     <= 1'b1;
                RX_DATA     <= d_shift_in;
                oa_state    <= IDLE;
            end

            INITIAL_SHIFT: begin
                    MISO_PAD    <= d_shift_out[BYTE_W - 1];
                    d_shift_out <= {d_shift_out[(BYTE_W - 2):0], 1'b0};
                    shift_ctr   <= shift_ctr + 1;
                    oa_state <= SHIFT_IN;
            end
        endcase
    end
endmodule