



module goertzel_loop_core
#(
    parameter D_W = 16,
    parameter B_W = 8
)
(
    input sys_clk,
    input enable,
    input start,
    input signed [(D_W - 1):0]coeff,

    input [(B_W - 1):0]data_n,

    output reg signed [15:0]T1,
    output reg signed [15:0]T2,

    output reg [8:0]read_address,

    output reg ready,
    output reg done
);
    reg [2:0]oa_state;

    localparam IDLE     = 3'h0;
    localparam RUN_0    = 3'h1;
    localparam RUN_1    = 3'h2;
    localparam POST_RESULTS = 3'h3;

    reg signed [(D_W - 1):0]coeff_buffer;
/*
dsp_16x16_fix14_16_signed_mul MUL0
    (
        .sys_clk(sys_clk),
        .dsp_CE(!internal_rst),
        .dsp_A(coeff_buffer),
        .dsp_B(T1_inter),
        .fix_14_16_Out(mul_res)
    );
*/
    wire signed [(D_W - 1):0]mul_res;

    reg signed [(D_W - 1):0]T2_pre;

    dsp_16x16_fix14_16_signed_mul MUL0
    (
        .sys_clk(sys_clk),
        .dsp_CE(enable),
        .dsp_A(coeff_buffer),
        .dsp_B(T1),
        .fix_14_16_Out(mul_res)
    );


    initial begin
        oa_state        = IDLE;
        T2_pre          = {D_W{1'b0}};
        T1              = {D_W{1'b0}};
        T2              = {D_W{1'b0}};
        coeff_buffer    = {D_W{1'b0}};

        ready           = 1'b0;
        done            = 1'b0;

        read_address    = {10{1'b0}};
    end

    always @ (posedge sys_clk) begin
        case (oa_state)
            IDLE: begin
                done    <= 1'b0;

                if(start) begin
                    oa_state        <= RUN_0;
                    T1              <= {D_W{1'b0}};
                    T2              <= {D_W{1'b0}};
                    T2_pre          <= {D_W{1'b0}};
                    coeff_buffer    <= coeff;
                    read_address    <= {9{1'b0}};
                end
            end
            RUN_0: begin
                ready       <= 1'b1;
                T2_pre      <= {8'h00, data_n[7:0]} - T2;
                oa_state    <= RUN_1;
            end
            RUN_1: begin
                T1 <= mul_res + T2_pre;
                T2 <= T1;

                if(read_address == 511) oa_state <= POST_RESULTS;
                else begin
                    read_address <= read_address + 1;
                    oa_state <= RUN_0;
                end
            end
            POST_RESULTS: begin
                ready   <= 1'b0;
                done    <= 1'b1;
                oa_state <= IDLE;
            end
        endcase
    end

endmodule