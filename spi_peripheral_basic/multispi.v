module multi_spi
#(
    parameter D_W = 8,
    parameter FIFO_DEPTH = 4
)
(
    input wire m_clk,
    input wire CSN,
    input wire SCK,
    input wire MOSI,
    output reg MISO,

   // input wire d_write_strobe,
    input wire [(D_W - 1):0]DATA_TO_SEND,
   // output wire TXFIFO_FULL,
    
   // input wire d_read_strobe,
   // output wire RXFIFO_DATA_PRESENT,
    output wire [(D_W - 1):0]DATA_RXD,
    
    output reg DREADY
);
    reg commit_vals_to_fifo;
    reg [1:0]commit_stage;
    reg [2:0]clk_ctr;
    reg [(D_W - 1):0]RX_BUFFER;
    reg [(D_W - 1):0]TX_BUFFER;

    reg [(D_W - 1):0]TX_STAGE;
    reg [(D_W - 1):0]RX_STAGE;
/*
    reg [1:0]TX_FIFO_PTR;
    reg [1:0]RX_FIFO_PTR;
    reg [(D_W - 1):0] TX_FIFO [3:0];
    reg [(D_W - 1):0] RX_FIFO [3:0];
*/

    assign DATA_RXD = RX_STAGE;

    initial begin
        MISO = 0;
        RX_BUFFER = 0;
        TX_BUFFER = 0;
        clk_ctr = 0;
        commit_vals_to_fifo = 0;

       // TX_FIFO_PTR = 0;
       // RX_FIFO_PTR = 0;

        TX_STAGE = 0;
        RX_STAGE = 0;

        DREADY = 0;
/*
        for(n = 0; n < FIFO_DEPTH; n = n + 1) begin
			RX_FIFO[n] = {(D_W) {1'b 0}};
			TX_FIFO[n] = {(D_W) {1'b 0}};	
		end
*/
    end

    // Hard lock mode 0:
    //  read on rising,
    //  shift on falling
    always @ (posedge SCK) begin
        RX_BUFFER[clk_ctr] <= MOSI;
    end

    always @ (negedge SCK) begin
       MISO = TX_BUFFER[clk_ctr];
       clk_ctr = clk_ctr + 1;
       if(!clk_ctr) commit_vals_to_fifo = 1;
    end

    always @ (posedge m_clk) begin
        if(commit_vals_to_fifo) begin
            commit_stage <= commit_stage + 1;
            commit_vals_to_fifo = 0;
        end
        else begin
            case(commit_stage)
                1: begin
                    RX_STAGE <= RX_BUFFER;
                    commit_stage <= commit_stage + 1;
                end

                2: begin
                    DREADY <= 1'b1;
                    commit_stage <= commit_stage + 1;
                end

                3: begin
                    TX_STAGE <= DATA_TO_SEND;
                    commit_stage <= commit_stage + 1;
                end
            endcase
        end

        /*
        case (commit_vals_to_fifo)
            1: commit_vals_to_fifo <= commit_vals_to_fifo + 1;
            2: begin
                RX_FIFO[RX_FIFO_PTR] <= RX_BUFFER;
                TX_BUFFER <= TX_FIFO[TX_FIFO_PTR];
                commit_vals_to_fifo <= commit_vals_to_fifo + 1;
            end
            3: begin
                RX_FIFO_PTR <= RX_FIFO_PTR + 1;
                TX_FIFO_PTR <= TX_FIFO_PTR + 1;
                commit_vals_to_fifo <= commit_vals_to_fifo + 1;
            end
        endcase
        */

    end

endmodule


