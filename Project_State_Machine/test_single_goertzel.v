

module t_goert_runtime
(
    input system_clk,
    input runme, 

    output reg [15:0]result
);
    localparam SIN_VAL = 16'h3CC5;
    localparam COS_VAL = 16'h1413;

    reg sys_clk_half;


    wire [8:0]sample_address;
    wire [7:0]sample_data;
    wire [15:0]cast_data;
    sample_bram SBRAM_0
    (
        .bram_clk(system_clk),
        .bram_ce(1'b1),
        .BRAM_ADDR(sample_address),
        .BRAM_OUT(sample_data)
    );

    //assign cast_data = {{8{1'b0}}, sample_data};


    wire valid_answer;
    wire [15:0]out_dat;

    goertzel_inner_pipelined_loop_component GCT1
    (
        .dsp_clk(sys_clk_half),
        .t_sin(SIN_VAL),
        .t_cos(COS_VAL),
        .data({8'h00, sample_data}),
        .sample_address(sample_address),

        .output_data(out_dat),
        .result_valid(valid_answer)
    );

    initial begin
        sys_clk_half = 1'b0;
        result = {16{1'b0}};
    end

    always @ (posedge system_clk) begin
        sys_clk_half <= ~sys_clk_half;
        if(valid_answer) result <= out_dat;
    end

endmodule