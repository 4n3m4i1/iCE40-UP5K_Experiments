module sin_bram
#(
    parameter SINBITS = 16,
    parameter SINSAMPLES = 256,
    parameter SINSAMPLEBITS = 8
)
(
    input bram_clk,                         // Clock...
    input bram_ce,                          // Read enable
    input [(SINSAMPLEBITS - 1):0]BRAM_ADDR, // 9 bit addressing
    output reg [(SINBITS - 1):0]BRAM_OUT    // 8 bit data out
);

    // Infer BRAM, single 16 x 256 instantiation
    reg [(SINBITS - 1):0] sin_samples [(SINSAMPLES - 1) : 0];

    initial begin
        // Read data into memory
        $readmemh("sin_table_8x512.mem", sin_samples);
    end

    always @ (posedge bram_clk) begin
        if(bram_ce) BRAM_OUT <= sin_samples[BRAM_ADDR];
    end

endmodule