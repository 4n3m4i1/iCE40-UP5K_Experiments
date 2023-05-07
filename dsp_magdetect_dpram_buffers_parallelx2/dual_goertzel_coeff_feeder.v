/*
    Upon a coeff rq a preset coefficient value will come out,

    this will increment thru hardcoded values until NUM_RUNS of coeff_rq
    has occured

    a run is defined as a single instance of a DSP process
    that means that in the parallel x2 DSP configuration a single
    processing cycle completes 2 runs
*/

module dual_goertz_coeff_banks
#(
    parameter NUM_RUNS = 10,
    parameter D_W = 16
)
(
    input sys_clk,
    input enable,
    input coeffs_rq,

    output wire [(D_W - 1):0]sin_out,
    output wire [(D_W - 1):0]cos_out,

    output reg d_ready
);
    
    reg [2:0]oa_state;
    localparam S0               = 3'h0;
    localparam S1               = 3'h1;
    localparam S2               = 3'h2;
    localparam S3               = 3'h3;
    localparam S4               = 3'h4;
    localparam S5               = 3'h5;
    localparam S6               = 3'h6;
    localparam S7               = 3'h7;

    wire [7:0]bin_sel;

    reg [8:0]run_ctr;

    run_addr_bram BINS2RUN
    (
        .bram_clk(!sys_clk),
        .bram_re(enable),
        .bram_addr(run_ctr),
        .bram_out(bin_sel)
    );


    sin_coeff_bram SINBRAM
    (
        .bram_clk(!sys_clk),
        .bram_re(enable),
        .bram_addr(bin_sel),
        .bram_out(sin_out)
    );

    cos_coeff_bram COSBRAM
    (
        .bram_clk(!sys_clk),
        .bram_re(enable),
        .bram_addr(bin_sel),
        .bram_out(cos_out)
    );

    initial begin
        oa_state    = S0;
        run_ctr     = 0;
        d_ready     = 0;
    end

    always @ (posedge sys_clk) begin
        case (oa_state)
            S0: begin
                if(coeffs_rq) begin
                    d_ready     <= 1'b1;
                    oa_state    <= S1;
                    run_ctr     <= run_ctr + 1;
                end
            end

            S1: begin
                d_ready         <= 1'b0;
                //run_ctr         <= run_ctr + 1;
                oa_state        <= S2;
            end

            S2: begin
                //d_ready         <= 1'b0;
                if(run_ctr == NUM_RUNS) run_ctr <= 0;
                oa_state        <= S0;
            end
        endcase
    end

endmodule


module sin_coeff_bram
#(
    parameter D_W = 16,
    parameter NUM_SAMPLES = 256,
    parameter NS_BITS = 8
)
(
    input bram_clk,
    input bram_re,
    input [(NS_BITS - 1):0]bram_addr,

    output reg [(D_W - 1):0]bram_out
);

    reg [(D_W - 1):0] bram_contents [0:(NUM_SAMPLES - 1)];

    initial begin
        $readmemh("sin_table.mem", bram_contents);
    end

    always @ (posedge bram_clk) begin
        if(bram_re) bram_out <= bram_contents[bram_addr];
    end

endmodule



module cos_coeff_bram
#(
    parameter D_W = 16,
    parameter NUM_SAMPLES = 256,
    parameter NS_BITS = 8
)
(
    input bram_clk,
    input bram_re,
    input [(NS_BITS - 1):0]bram_addr,

    output reg [(D_W - 1):0]bram_out
);

    reg [(D_W - 1):0] bram_contents [0:(NUM_SAMPLES - 1)];

    initial begin
        $readmemh("cos_table.mem", bram_contents);
    end

    always @ (posedge bram_clk) begin
        if(bram_re) bram_out <= bram_contents[bram_addr];
    end

endmodule


// Holds runtime sequencing that dictates which coefficients are
//  output per processing cycle
module run_addr_bram
#(
    parameter D_W = 8,
    parameter NUM_SAMPLES = 512,
    parameter NS_BITS = 9
)
(
    input bram_clk,
    input bram_re,
    input [(NS_BITS - 1):0]bram_addr,

    output reg [(D_W - 1):0]bram_out
);

    reg [(D_W - 1):0] bram_contents [0:(NUM_SAMPLES - 1)];

    initial begin
        $readmemh("run_table.mem", bram_contents);
    end

    always @ (posedge bram_clk) begin
        if(bram_re) bram_out <= bram_contents[bram_addr];
    end

endmodule