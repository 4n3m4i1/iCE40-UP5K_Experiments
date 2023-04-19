
module goertzel_single
#(
    parameter NUM_SAMPLES = 512,
    parameter D_W = 16
)
(
    input dsp_clk,
    input en,
    input run_looping,

    input wire signed [(D_W - 1):0]t_sin,
    input wire signed [(D_W - 1):0]t_cos,

    input [7:0]sample_data_in,

    output reg [8:0]sample_address,

    output reg goert_done,
    output reg [(D_W - 1):0]goert_mag
);

    reg [2:0]run_edge_detection;

    reg [9:0]looper;

    reg [2:0]oa_state;

    reg [1:0]loop_state;

    reg signed [(D_W - 1):0]t0, t1, t2;

    reg signed [(D_W - 1):0]coeff;
    reg signed [(D_W - 1):0]negative_cos;


    reg signed [(D_W - 1):0]zero_fixed;

/*
module dsp_16x16_fix14_16_signed_mac
#(
    parameter D_W = 16
)
(
    input sys_clk,
    input dsp_CE,
    input [(D_W - 1):0]dsp_A,
    input [(D_W - 1):0]dsp_B,
    input [(D_W - 1):0]dsp_C,
    input [(D_W - 1):0]dsp_D,
    output [(D_W - 1):0]fix_14_16_Out
);
*/
    reg signed [(D_W - 1):0]MUL_TERM_0;     // A
    reg signed [(D_W - 1):0]MUL_TERM_1;     // B
    reg signed [(D_W - 1):0]MUL_ADD_0;      // D

    wire signed [(D_W - 1):0]MUL_RESULT;    // in fix14_16 format

    dsp_16x16_fix14_16_signed_mac GMUL      // Unregistered: FixedPt[15:0] = ((A[15:0] * B[15:0]) + (MUL_ADD[15:0] << 14)) >> 14;
    (
        .sys_clk(dsp_clk),
        .dsp_CE(en),
        .dsp_A(MUL_TERM_0),         // A
        .dsp_B(MUL_TERM_1),         // B
        .dsp_C({2'b00, MUL_ADD_0[15:2]}),       // Apply shift to added term
        .dsp_D({MUL_ADD_0[1:0], {14{1'b0}}}),   // Apply shift to added term
        .fix_14_16_Out(MUL_RESULT)  // O, preformatted for fixed pt
    );


    initial begin
        run_edge_detection = {(3){1'b0}};
        looper = {(10){1'b0}};
        oa_state = {(3){1'b0}};

        t0 = {(D_W){1'b0}};
        t1 = {(D_W){1'b0}};
        t2 = {(D_W){1'b0}};

        coeff = {(D_W){1'b0}};
        negative_cos = {(D_W){1'b0}};

        MUL_TERM_0 = {(D_W){1'b0}};
        MUL_TERM_1 = {(D_W){1'b0}};
        
        MUL_ADD_0 = {(D_W){1'b0}};
        
        zero_fixed = {(D_W){1'b0}};

        loop_state = 2'b00;

        goert_done = 1'b0;
        goert_mag = {(D_W){1'b0}};

        sample_address = {(9){1'b0}};
    end


    always @ (posedge dsp_clk) begin
        if(en) begin        // Run
            case (oa_state)
                0: begin    // Wait for RUN signal
                    run_edge_detection <= {run_edge_detection[1],
                                            run_edge_detection[0],
                                            run_looping};

                    if(run_edge_detection == 3'b011) begin
                        oa_state <= oa_state + 1;
                        coeff <= {t_cos[14:0], 1'b0};
                        negative_cos <= ~(t_cos[15:0]) + 1;
                        loop_state <= 2'b00;
                        looper <= {10{1'b0}};
                    end
                end

                1: begin    // Loop processing
                    if(looper[9]) begin
                        oa_state <= oa_state + 1;
                    end else begin
                        case(loop_state)
                            2'b00: begin
                                MUL_TERM_0 <= coeff;
                                MUL_TERM_1 <= t1;
                                MUL_ADD_0 <= {{(8){sample_data_in[7]}}, sample_data_in[7:0]} - t2;
                                loop_state <= loop_state + 1;
                                sample_address <= sample_address + 1;
                            end
                            2'b01: begin
                                //sample_address <= sample_address + 1;
                                t0 <= MUL_RESULT;
                                t2 <= t1;
                                t1 <= t0;
                                //loop_state <= loop_state + 1;
                                loop_state <= 2'b00;
                                looper <= looper + 1;
                            end
                            2'b10: begin
                                t0 <= MUL_RESULT;
                                t2 <= t1;
                                loop_state <= loop_state + 1;
                            end
                            2'b11: begin
                                t1 <= t0;

                                loop_state <= loop_state + 1;
                                looper <= looper + 1;
                            end
                        endcase
                    end
                end

                2: begin    // Post process
                    MUL_TERM_0 <= t2;
                    MUL_TERM_1 <= negative_cos;
                    MUL_ADD_0 <= t1;
                    oa_state <= oa_state + 1;
                end

                3: begin
                    t1 <= MUL_RESULT;
                    
                    MUL_TERM_0 <= t2;
                    MUL_TERM_1 <= t_sin;
                    MUL_ADD_0 <= zero_fixed;
                    
                    oa_state <= oa_state + 1;
                end

                4: begin
                    t2 <= MUL_RESULT;

                    MUL_TERM_0 <= t1;
                    MUL_TERM_1 <= t1;

                    oa_state <= oa_state + 1;
                end

                5: begin
                    t1 <= MUL_RESULT;

                    MUL_TERM_0 <= t2;
                    MUL_TERM_1 <= t2;

                    oa_state <= oa_state + 1;
                end

                6: begin
                    t2 <= MUL_RESULT;

                    oa_state <= oa_state + 1;
                end

                7: begin
                    goert_mag <= t1 + t2;
                    goert_done <= 1'b1;
                end

            endcase
        end
        else begin          // Reset
            oa_state <= 3'b000;
            run_edge_detection <= 3'b000;
            looper <= {(10){1'b0}};
            t0 <= {(D_W){1'b0}};
            t1 <= {(D_W){1'b0}};
            t2 <= {(D_W){1'b0}};
            loop_state <= 2'b00;

            goert_mag <= {(D_W){1'b0}};
            goert_done <= 1'b0;

            sample_address <= {(9){1'b0}};
        end
    end
endmodule