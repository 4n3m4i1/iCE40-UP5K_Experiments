


module parallel_goertzel
#(
    parameter NUM_RUNS = 8
)
(
    input sys_clk,
    input adc_ready,
    input adc_data_rdy,
    input [7:0]adc_data,

    output wire [15:0]G0,
    output wire [15:0]G1,
    output wire G_READY
);


    wire trig_dreq, trig_rdy;
    wire [15:0]sin_interconn, cos_interconn;
    dsp_goertzel_manager_dual GOERT_x2
    (
        .sys_clk(sys_clk),
        .adc_rdy(adc_ready),
        .adc_data_in(adc_data),
        .adc_data_ready(adc_data_rdy),

        .goertzel_mag_0(G0),
        .goertzel_mag_1(G1),
        .mag_rdy(G_READY),
        
        .num_runs(5'h5),

        .request_trig(trig_dreq),
        .trig_ready(trig_rdy),
        .sin_in(sin_interconn),
        .cos_in(cos_interconn)
    );


    dual_goertz_coeff_banks CFF_BANK_DATA
    (
        .sys_clk(sys_clk),
        .enable(adc_ready),
        .coeffs_rq(trig_dreq),
        .sin_out(sin_interconn),
        .cos_out(cos_interconn),
        .d_ready(trig_rdy)
    );

endmodule