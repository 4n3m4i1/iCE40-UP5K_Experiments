module SIN_NCO
#(
    parameter SAMPLE_W = 16,
    parameter SAMPLE_CT = 256,
    parameter SAMPLE_CT_BITS = 8
)
(
    input clk,
    input wire [15:0]nco_div,
    output reg [(SAMPLE_W - 1):0]nco_out,
    output wire ncoovfsync
);

    reg [15:0]nco_div_buffer;

    reg [15:0] nco_clk_div_acc;
    reg bram_rd;
    reg [(SAMPLE_CT_BITS - 1):0]bram_addr;

    wire [(SAMPLE_W - 1):0]bramo;

    reg [2:0]bram_rd_state;

    /*
    module sin_bram
    (
    input bram_clk,                         // Clock...
    input bram_ce,                          // Read enable
    input [(SINSAMPLEBITS - 1):0]BRAM_ADDR, // 9 bit addressing
    output reg [(SINBITS - 1):0]BRAM_OUT    // 8 bit data out
    );
    */

    sin_bram SBRM
    (
        .bram_clk(clk),
        .bram_ce(bram_rd),
        .BRAM_ADDR(bram_addr),
        .BRAM_OUT(bramo)
    );

    assign ncoovfsync = (!bram_addr && !bram_rd_state) ? 1'b1 : 1'b0;

    initial begin
        bram_addr = 0;
        bram_rd = 0;
        nco_clk_div_acc = {16{1'b0}};
        nco_out = {(SAMPLE_W){1'b0}};
        bram_rd_state = 3'b000;
    end

    always @ (posedge clk) begin
        nco_clk_div_acc = nco_clk_div_acc + 1;
        
        nco_div_buffer <= nco_div;
        
        if(nco_clk_div_acc >= nco_div_buffer) begin
            nco_clk_div_acc <= {16{1'b0}};
            
            bram_addr <= bram_addr + 1;
            bram_rd <= 1'b1;
            
            //if(!bram_rd) bram_rd_state <= bram_rd_state + 1;
        end

        if(bram_rd) begin
            nco_out = bramo;
            bram_rd = 1'b0;
        end

/*
        else begin
            case (bram_rd_state)
                1: begin
                    bram_rd_state <= bram_rd_state + 1;
                    bram_rd <= 1'b1;
                end
                
                2: bram_rd_state <= bram_rd_state + 1;

                //3: bram_rd_state <= bram_rd_state + 1;

                3: begin
                    bram_rd <= 1'b0;
                    nco_out <= bramo;
                    bram_rd_state <= 3'b000;
                end
            endcase
        end
*/
    end

    // Bram read state machine
    //  == 0, idle
    //  == 1, read initiate
    //  == 2, wait



endmodule