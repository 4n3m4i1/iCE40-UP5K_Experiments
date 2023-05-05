module dsp_tb();
    reg sys_clk;


    // Bin 99, 97.6k
    localparam SIN_97K6 = 16'h3BFD;     //400
    localparam COS_97K6 = 16'h164C;

    // Bin 102, 100k
    localparam SIN_100K = 16'h3CC5; // 32k
    localparam COS_100K = 16'h1413;

    // Bin 110, 108k
    localparam SIN_108K = 16'h3E71; // 162
    localparam COS_108K = 16'h0F8C;
    
    // Bin 153, 150k
    localparam SIN_150K = 16'h3D02; // 2
    localparam COS_150K = 16'hECAC;

    reg signed [15:0] sin_dat [0:3];
    reg signed [15:0] cos_dat [0:3];

    reg [7:0] test_data [0:511];
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
    wire gmagrdy, trig_rq;

    wire signed [15:0]sin_c, cos_c;
    reg [1:0]j;

    assign sin_c = sin_dat[j];
    assign cos_c = cos_dat[j];

    reg [4:0]NRS;

    dsp_goertzel_manager DSGOER
    (
        .sys_clk(sys_clk),
        .adc_rdy(dsp_ce),
        .adc_data_ready(adc_dat_write),
        .adc_data_in(dsp_adc_data),
        .goertzel_mag(goertzel_mag),
        .mag_rdy(gmagrdy),

        .request_trig(trig_rq),
        .sin_in(sin_c),
        .cos_in(cos_c),
        .num_runs(NRS)
    );


    integer n, m;
    
    initial begin
        NRS         = 4;
        sin_dat[0] = SIN_97K6;
        cos_dat[0] = COS_97K6;

        sin_dat[1] = SIN_100K;
        cos_dat[1] = COS_100K;

        sin_dat[2] = SIN_108K;
        cos_dat[2] = COS_108K;

        sin_dat[3] = SIN_150K;
        cos_dat[3] = COS_150K;

        //sin_c = 0;
        //cos_c = 0;

        m = 0; n = 0;
        j = 0;

        $readmemh("sample_table_8x512.mem", test_data);
        dsp_ce = 0;
        adc_dat_write = 0;
        dsp_adc_data = 0;

        #20;
        dsp_ce = 1;
        #200;

        for(m = 0; m < 16; m = m+1) begin
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

    always @ (posedge sys_clk) begin
        if(trig_rq) begin
            //sin_c <= sin_dat[j];
            //cos_c <= cos_dat[j];
            j <= j + 1;
        end
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

