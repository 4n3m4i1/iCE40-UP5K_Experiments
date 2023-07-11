


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
    output wire G_READY,
    output wire [4:0]current_run
);

    /*
        Handles ADC sample bank switching
        and automatic runs of the preprogrammed
        tables found below.

        Outputs 2 16 bit magnitudes per processing interval
    */
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
        
        .num_runs(5'h5),        // A run in this unique case includes 2 runs, mul by 2 for conversion
        .mag_run(current_run),         
        
        .request_trig(trig_dreq),
        .trig_ready(trig_rdy),
        .sin_in(sin_interconn),
        .cos_in(cos_interconn)
    );

    /*
        Source of DSP run trig coefficients
        Can support any arbitrary bin(s) and any arb
        pattern. This pattern is loaded from run_table.mem.
        Each processing time interval completes 2 runs,
        thus each pair of entries in the table run in parallel,
        then the next pair run, etc..
    */
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