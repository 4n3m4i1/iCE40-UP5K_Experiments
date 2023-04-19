
module goertzel_inner_pipelined_loop_component
(
    input dsp_clk,
    //input signed [15:0]t1,
    //input signed [15:0]t2,
    input signed [15:0]data,

    input signed [15:0]t_sin,
    input signed [15:0]t_cos,

    //output signed [15:0]t1_out
    output reg [8:0]sample_address,

    output reg [15:0]output_data,
    output reg result_valid
);
    wire [15:0]coeff;

    assign coeff = {t_cos[14:0], 1'b0};

    reg [15:0]t1;

    reg [15:0]t2;   // T2 == last T1




    wire signed [15:0]stage_0_output_t0;

    dsp_16x16_fix14_16_signed_mul stage_0_mul
    (
        .sys_clk(dsp_clk),
        .dsp_CE(1'b1),
        .dsp_A(coeff),
        .dsp_B(t1),
        .fix_14_16_Out(stage_0_output_t0)
    );


    wire signed [15:0]adder_sub_out; 
    wire signed [15:0]adder_t0_out;

   

    dsp_16x16_fix14_16_signed_adder stage_0_1_add_sub
    (
        .sys_clk(dsp_clk),
        .dsp_CE(1'b1),
        .dsp_A(adder_sub_out),
        .dsp_B(t2),
        .dsp_C(stage_0_output_t0),
        .dsp_D(data),
        .dsp_o({adder_t0_out[15:0], adder_sub_out[15:0]})
    );
    // (data - t2) -> t0
    //  t0 + (coeff * t1) -> adder_t0_out

    wire signed [15:0]post_process_t1, post_process_t2;
    dsp_16x16_fix14_16_signed_mul t1_post_process
    (
        .sys_clk(dsp_clk),
        .dsp_CE(1'b1),
        .dsp_A(t2),
        .dsp_B((~t_cos) + 15'h01),
        .fix_14_16_Out(post_process_t1)
    );

    dsp_16x16_fix14_16_signed_mul t2_post_process
    (
        .sys_clk(dsp_clk),
        .dsp_CE(1'b1),
        .dsp_A(t2),
        .dsp_B(t_sin),
        .fix_14_16_Out(post_process_t2)
    );

    wire signed [15:0]t1_sqrd, t2_sqrd;

    dsp_16x16_fix14_16_signed_mul mag_finder_1
    (
        .sys_clk(dsp_clk),
        .dsp_CE(1'b1),
        .dsp_A(post_process_t1),
        .dsp_B(post_process_t1),
        .fix_14_16_Out(t1_sqrd)
    );

    dsp_16x16_fix14_16_signed_mul mag_finder_2
    (
        .sys_clk(dsp_clk),
        .dsp_CE(1'b1),
        .dsp_A(post_process_t2),
        .dsp_B(post_process_t2),
        .fix_14_16_Out(t2_sqrd)
    );

    initial begin
        sample_address = {(9){1'b0}};
        t1 = {16{1'b0}};
        t2 = {16{1'b0}};
        output_data = {16{1'b0}};
        result_valid = 1'b0;
    end

    always @ (posedge dsp_clk) begin
        t2 <= t1;
        t1 <= adder_t0_out;

        sample_address <= sample_address + 1;

        output_data <= t1_sqrd + t2_sqrd;

        if(sample_address == 0) begin
            result_valid <= 1'b1;
            //output_data <= t1_sqrd + t2_sqrd;
            t1 = {16{1'b0}};
            t2 = {16{1'b0}};
        end
        else begin
            result_valid <= 1'b0;
        end
    end

endmodule
























