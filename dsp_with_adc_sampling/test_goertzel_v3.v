/*
    Goertzel_v3 will run the accumulation loop over the sample
    table of N (512) samples,

    Goertzel top will issue coefficients and post process
    with trig table values
*/
module goertzel_top_v3
#(
    parameter BYTE_W = 8,
    parameter D_W = 16,
    parameter SHAMT = 14,
    parameter NUM_SAMPLES = 512,
    parameter SAMPLE_W = 8,
    parameter SAMPLE_BITS = 9
)
(
    input sys_clk,
    input bank_switch,

    output wire [(SAMPLE_BITS - 1):0]bank_addr,
    input wire  [(SAMPLE_W - 1):0]bank_data,

    output reg goertzel_done,
    output reg signed [(D_W - 1):0]goertzel_mag
);
    reg [2:0]oa_state;
    localparam IDLE         = 0;
    localparam SETUP_CV     = 1;
    localparam WAIT_4_CV    = 2;
    localparam POST_PRO_0   = 3;
    localparam CLEANUP      = 5;

    reg [1:0]bank_sw_detect;
    

    reg signed [(D_W - 1):0]T_SIN, T_COS, INV_COS;
    wire signed [(D_W - 1):0]COEFF, T1_RESULT, T2_RESULT;

    assign COEFF = {T_COS[(D_W - 2):0], 1'b0};

    reg start_goertzel_loop;
    wire goertzel_loop_done;
    // Runs loop
    goertzel_v3 GV03
    (
        .sys_clk(sys_clk),
        .start_cvt(start_goertzel_loop),
        .data_in(bank_data),
        .data_address(bank_addr),
        .coeff(COEFF),
        .T1_RES(T1_RESULT),
        .T2_RES(T2_RESULT),
        .dsp_done(goertzel_loop_done)
    );


    reg enable_post_process_dsp, start_post_process;
    wire [(D_W - 1):0]final_mag;
    wire post_process_finished;
    goertzel_v3_post_process GPP0
    (
        .en_dsp(enable_post_process_dsp),
        .sys_clk(sys_clk),
        .start_post_process(start_post_process),
        .T1(T1_RESULT),
        .T2(T2_RESULT),
        .SIN(T_SIN),
        .INV_COS(INV_COS),
        .post_process_done(post_process_finished),
        .goertzel_mag(final_mag)
    );

    initial begin
        bank_sw_detect = 2'b00;
        oa_state    = 3'b000;
        start_goertzel_loop = 1'b0;
        T_SIN       = {D_W{1'b0}};
        T_COS       = {D_W{1'b0}};
        INV_COS     = {D_W{1'b0}};
        enable_post_process_dsp = 1'b0;
        start_post_process = 1'b0;
    end

    always @ (posedge sys_clk) begin
        bank_sw_detect <= {bank_sw_detect[0], bank_switch};

        case (oa_state)
            IDLE: begin
                enable_post_process_dsp <= 1'b0;
                if(bank_sw_detect[1] != bank_sw_detect[0]) begin
                    oa_state        <= SETUP_CV;
                    T_SIN           <= 16'h3CC5;
                    T_COS           <= 16'h1413;
                    INV_COS         <= 16'h7A63;
                end
            end
            SETUP_CV: begin
                start_goertzel_loop <= 1'b1;
                oa_state            <= WAIT_4_CV;
            end
            WAIT_4_CV: begin
                start_goertzel_loop     <= 1'b0;
                enable_post_process_dsp <= 1'b1;
                if(goertzel_loop_done) oa_state <= POST_PRO_0;
            end
            POST_PRO_0: begin
                start_post_process      <= 1'b1;
                if(post_process_finished) begin
                    goertzel_mag    <= final_mag;
                    goertzel_done   <= 1'b1;
                    oa_state        <= CLEANUP;
                    goertzel_done   <= 1'b0;
                end
            end
            CLEANUP: begin
                goertzel_done       <= 1'b0;
                oa_state            <= IDLE;
            end
        endcase
    end
endmodule




module goertzel_v3
#(
    parameter BYTE_W = 8,
    parameter D_W = 16,
    parameter SHAMT = 14,
    parameter NUM_SAMPLES = 512,
    parameter SAMPLE_W = 8,
    parameter SAMPLE_BITS = 9
)
(
    input sys_clk,
    input start_cvt,

    input [(SAMPLE_W - 1):0]data_in,
    output reg [(SAMPLE_BITS - 1):0]data_address,

    input wire signed [(D_W - 1):0]coeff,

    output reg signed [(D_W - 1):0]T1_RES,
    output reg signed [(D_W - 1):0]T2_RES,
    output reg dsp_done
);
    localparam IDLE     = 0;
    localparam RESET    = 1;
    localparam RUN_DSP  = 2;
    localparam CLEANUP  = 3;

    reg [1:0]oa_state;
    
    reg internal_rst;
    reg signed [(D_W - 1):0]coeff_buffer;

    wire signed [(D_W - 1):0]mul_res, T1_inter, T2_inter, sub_0, add_0;

    assign sub_0 = data_in - T2_inter;
    assign add_0 = mul_res + sub_0;

    dsp_16x16_fix14_16_signed_mul MUL0
    (
        .sys_clk(sys_clk),
        .dsp_CE(!internal_rst),
        .dsp_A(coeff_buffer),
        .dsp_B(T1_inter),
        .fix_14_16_Out(mul_res)
    );

    dsp_fixed_dff T1_PIPE
    (
        .sys_clk(sys_clk),
        .rst(internal_rst),
        .D(add_0),
        .Q(T1_inter)
    );

    dsp_fixed_dff T2_PIPE
    (
        .sys_clk(sys_clk),
        .rst(internal_rst),
        .D(T1_inter),
        .Q(T2_inter)
    );



    initial begin
        dsp_done    =  1'b0;
        oa_state    = IDLE;
        
        T1_RES      = {D_W{1'b0}};
        T2_RES      = {D_W{1'b0}};
        coeff_buffer = {D_W{1'b0}};
        internal_rst = 1'b0;

        data_address = {SAMPLE_BITS{1'b0}};
    end



    always @ (posedge sys_clk) begin
        

        case (oa_state)
            IDLE: begin
                dsp_done            <= 1'b0;
                if(start_cvt) begin
                    internal_rst    <= 1'b1;
                    oa_state        <= RESET;
                    data_address    <= {SAMPLE_BITS{1'b0}};
                end
            end

            RESET: begin
                oa_state        <= RUN_DSP;
            end
            RUN_DSP: begin
                internal_rst    <= 1'b0;
                data_address    <= data_address + 1;
                if(data_address == (NUM_SAMPLES - 1)) oa_state <= CLEANUP;
            end
            CLEANUP: begin
                T1_RES      <= T1_inter;
                T2_RES      <= T2_inter;
                dsp_done    <= 1'b1;
                oa_state    <= IDLE;
            end
        endcase
    end
endmodule



module goertzel_v3_post_process
#(
    parameter BYTE_W = 8,
    parameter D_W = 16,
    parameter SHAMT = 14,
    parameter NUM_SAMPLES = 512,
    parameter SAMPLE_W = 8,
    parameter SAMPLE_BITS = 9
)
(
    input en_dsp,
    input sys_clk,
    input start_post_process,

    input signed [(D_W - 1):0]T1,
    input signed [(D_W - 1):0]T2,
    input signed [(D_W - 1):0]SIN,
    input signed [(D_W - 1):0]INV_COS,  // cos * -1

    output reg post_process_done,
    output reg [(D_W - 1):0]goertzel_mag
);
    reg [1:0]oa_state;
    localparam IDLE     = 0;
    localparam STAGE_0  = 1;
    localparam STAGE_1  = 2;

    reg [(D_W - 1):0]MUL_0_A, MUL_0_B;
    wire [(D_W - 1):0]MUL_0_RES;

    dsp_16x16_fix14_16_signed_mul MUL0
    (
        .sys_clk(sys_clk),
        .dsp_CE(en_dsp),
        .dsp_A(MUL_0_A),
        .dsp_B(MUL_0_B),
        .fix_14_16_Out(MUL_0_RES)
    );

    reg [(D_W - 1):0]MUL_1_A, MUL_1_B;
    wire [(D_W - 1):0]MUL_1_RES;

    dsp_16x16_fix14_16_signed_mul MUL1
    (
        .sys_clk(sys_clk),
        .dsp_CE(en_dsp),
        .dsp_A(MUL_1_A),
        .dsp_B(MUL_1_B),
        .fix_14_16_Out(MUL_1_RES)
    );


    initial begin
        oa_state          = IDLE;
        MUL_0_A           = {D_W{1'b0}};
        MUL_0_B           = {D_W{1'b0}};
        MUL_1_A           = {D_W{1'b0}};
        MUL_1_B           = {D_W{1'b0}};
        post_process_done = 1'b0;
        goertzel_mag = {D_W{1'b0}};
    end

    always @ (posedge sys_clk) begin
        case (oa_state)
            IDLE: begin
                post_process_done <= 1'b0;
                if(start_post_process) begin
                    MUL_0_A     <= INV_COS;
                    MUL_0_B     <= T1;
                    MUL_1_A     <= T2;
                    MUL_1_B     <= SIN;
                    oa_state    <= STAGE_0;
                end
            end
            STAGE_0: begin
                MUL_0_A     <= MUL_0_RES;
                MUL_0_B     <= MUL_0_RES;

                MUL_1_A     <= MUL_1_RES;
                MUL_1_B     <= MUL_1_RES;

                oa_state    <= STAGE_1;
            end
            STAGE_1: begin
                goertzel_mag <= MUL_0_RES + MUL_1_RES;
                post_process_done <= 1'b1;
            end
        endcase
    end
endmodule


module dsp_fixed_dff
#(
    parameter D_W = 16
)
(
    input sys_clk,
    input rst,
    input signed [(D_W - 1):0]D,
    output reg signed [(D_W - 1):0]Q
);


    initial begin
        Q = {D_W{1'b0}};
    end

    always @ (posedge sys_clk) begin
        if(rst) Q <= {D_W{1'b0}};
        else Q <= D;
    end
endmodule


