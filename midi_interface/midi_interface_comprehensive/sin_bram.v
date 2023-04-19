module fixed_15_sin_bram
#(
    parameter DATA_W = 16,
    parameter SAMPLE_CT = 256,
    parameter SAMPLE_ADDR_BITS = 8
)
(
    input bram_clk,
    input bram_ce,
    input [(SAMPLE_ADDR_BITS - 1):0]bram_addr,
    output reg [(DATA_W - 1):0]bram_out
);

    reg [(DATA_W - 1):0] wavetable [(SAMPLE_CT - 1):0];


    initial begin
        $readmemh("sin_table_16x256.mem", wavetable);
    end

    always @ (posedge bram_clk) begin
        if(bram_ce) bram_out <= wavetable[bram_addr];
    end
endmodule