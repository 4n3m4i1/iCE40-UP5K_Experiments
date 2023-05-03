module dsp_tb();
    reg sys_clk;



    reg [7:0] test_data [0:512];
/*
module dsp_goertzel_manager
#(
    parameter D_W = 8,
    parameter B_W = 8,
    parameter NUM_SAMPLES = 512,
    parameter NS_BITS = 9
)
(
    input sys_clk,

    input adc_rdy,

    input adc_data_ready,
    input [(B_W - 1):0]adc_data_in,

    output reg [15:0]goertzel_mag,
    output reg mag_rdy
);
*/
    reg dsp_ce;
    reg adc_dat_write;

    reg [7:0]dsp_adc_data;

    wire [15:0]goertzel_mag;
    wire gmagrdy;

    dsp_goertzel_manager DSGOER
    (
        .sys_clk(sys_clk),
        .adc_rdy(dsp_ce),
        .adc_data_ready(adc_dat_write),
        .adc_data_in(dsp_adc_data),
        .goertzel_mag(goertzel_mag),
        .mag_rdy(gmagrdy)
    );


    integer n;
    initial begin
        $readmemh("sample_table_8x512.mem", test_data);
        dsp_ce = 0;
        adc_dat_write = 0;
        dsp_adc_data = 0;

        #20;
        dsp_ce = 1;
        #200;
        for(n = 0; n < 512; n = n+1) begin
            dsp_adc_data = test_data[n];
            adc_dat_write = 1;
            #42;
            adc_dat_write = 0;
            #1958;
        end

        for(n = 0; n < 512; n = n+1) begin
            dsp_adc_data = test_data[n];
            adc_dat_write = 1;
            #42;
            adc_dat_write = 0;
            #1958;
        end

        for(n = 0; n < 512; n = n+1) begin
            dsp_adc_data = test_data[n];
            adc_dat_write = 1;
            #42;
            adc_dat_write = 0;
            #1958;
        end

        for(n = 0; n < 512; n = n+1) begin
            dsp_adc_data = test_data[n];
            adc_dat_write = 1;
            #42;
            adc_dat_write = 0;
            #1958;
        end

        for(n = 0; n < 512; n = n+1) begin
            dsp_adc_data = test_data[n];
            adc_dat_write = 1;
            #42;
            adc_dat_write = 0;
            #1958;
        end

        for(n = 0; n < 512; n = n+1) begin
            dsp_adc_data = test_data[n];
            adc_dat_write = 1;
            #42;
            adc_dat_write = 0;
            #1958;
        end


        $finish;
    end


    initial begin
        $dumpfile("dsp_tb.vcd");
        $dumpvars(0,dsp_tb);
    end

    initial begin       // FPGA clk, 24MHz
        sys_clk = 0;
        
        forever begin
            #21;
            sys_clk <= ~sys_clk;
        end
    end
endmodule

