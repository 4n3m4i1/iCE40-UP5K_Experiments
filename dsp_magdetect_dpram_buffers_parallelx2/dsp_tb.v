module dsp_tb();
    reg sys_clk;

    reg [7:0] test_data [0:511];

/*
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
*/
    reg dsp_ce, adc_dat_write;
    reg [7:0]dsp_adc_data;

    wire [15:0]G0_MAG, G1_MAG;
    wire G_MAG_DONE;

    parallel_goertzel PG0
    (
        .sys_clk(sys_clk),
        .adc_ready(dsp_ce),
        .adc_data_rdy(adc_dat_write),
        .adc_data(dsp_adc_data),

        .G0(G0_MAG),
        .G1(G1_MAG),
        .G_READY(G_MAG_DONE)
    );

    integer n, m;
    
    initial begin
        m = 0; n = 0;

        $readmemh("sample_table_8x512.mem", test_data);
        dsp_ce = 0;
        adc_dat_write = 0;
        dsp_adc_data = 0;

        #20;
        dsp_ce = 1;
        #200;

        for(m = 0; m < 4; m = m+1) begin
            for(n = 0; n < 512; n = n+1) begin
                dsp_adc_data = test_data[n];
                adc_dat_write = 1;
                #42;
                adc_dat_write = 0;
                #1958;
            end
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

