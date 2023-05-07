/*
    Dual goertzels run in paralle as the multiplier arrangement in the ice40up5k
    allows this fairly well

    stacking more in parallel may incur large routing costs
*/



module dsp_goertzel_manager_dual
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

    output reg [15:0]goertzel_mag_0,
    output reg [15:0]goertzel_mag_1,
    output reg mag_rdy,

    output reg request_trig,
    input trig_ready,
    input signed [15:0]sin_in,
    input signed [15:0]cos_in,
    // Must be at least 1
    input [4:0]num_runs                 // Number of loops to run. New trig coeff will be requester for each run.
);

    localparam IDLE             = 4'h0;     // Wait for bank change
    localparam START            = 4'h1;     // Rq new trig coeffs
    localparam GET_TRIG_0       = 4'h2;     // Get trig coeff for DSP inst 0
    localparam GTR_STALL_0      = 4'h3;
    localparam GET_TRIG_1       = 4'h4;     // Get trig coeff for DSP inst 1
    localparam STALL            = 4'h5;     // Find which bank to run DSP on
    localparam RUN_BANK_LOOP    = 4'h6;
    localparam RUN_BANK_PP      = 4'h7;
    localparam RUN_BANK_PP_1    = 4'h8;
    localparam RUN_BANK_PP_2    = 4'h9;
    localparam RUN_BANK_PP_3    = 4'hA;
    localparam RUN_BANK_PP_4    = 4'hB;
    
    

    reg [3:0]oa_state;

    reg wr_en_0, rd_en_0;
    reg wr_en_1, rd_en_1;

    reg [(NS_BITS - 1):0]wr_address;
    wire [(NS_BITS - 1):0]rd_address;

    wire [(B_W - 1):0]rd_dat_0, rd_dat_1;

    wire [(B_W - 1):0]read_bank_data;

    assign read_bank_data = (bank_select) ? rd_dat_0 : rd_dat_1;

    reg bank_select;            // Write to this bank
    reg old_bank_select;

    wire bank_chg_detect;
    assign bank_chg_detect = bank_select ^ old_bank_select;

    

    // Bank 0
    dual_port_bram_8x512 DPRAM0
    (
        .clk(!sys_clk),
        .rd_enable(rd_en_0),
        .wr_enable(wr_en_0),

        .rd_address(rd_address),
        .wr_address(wr_address),

        .wr_data_in(adc_data_in),
        .rd_data_out(rd_dat_0)
    );

    // Bank 1
    dual_port_bram_8x512 DPRAM1
    (
        .clk(!sys_clk),
        .rd_enable(rd_en_1),
        .wr_enable(wr_en_1),

        .rd_address(rd_address),
        .wr_address(wr_address),

        .wr_data_in(adc_data_in),
        .rd_data_out(rd_dat_1)
    );


    reg goert_loop_start;
    wire goert_ready, goert_loop_done;
    wire goert_loop_cmplt_0, goert_loop_cmplt_1;

    assign goert_loop_done = goert_loop_cmplt_0 && goert_loop_cmplt_1;
//////////////////////////////////////// DSP Instance 0 ////////////////////////
    reg signed [15:0]t_sin_0;
    reg signed [15:0]t_cos_0, inv_cos_0;
    
    wire signed [15:0]T1_OUT_0, T2_OUT_0;
    reg signed [15:0]T1_BUFF_0, T2_BUFF_0;

    goertzel_loop_core GLC_0
    (
        .sys_clk(sys_clk),
        .enable(adc_rdy),
        .start(goert_loop_start),
        .coeff({t_cos_0[14:0], 1'b0}),    // cos * 2
        .data_n(read_bank_data),

        .T1(T1_OUT_0),
        .T2(T2_OUT_0),
        .read_address(rd_address),
        .ready(goert_ready),
        .done(goert_loop_cmplt_0)
    );

    reg signed [15:0]PP_A_0, PP_B_0;
    wire signed [15:0]PP_OUT_0;

    dsp_16x16_fix14_16_signed_mul PP_MUL_0
    (
        .sys_clk(sys_clk),
        .dsp_CE(adc_rdy),
        .dsp_A(PP_A_0),
        .dsp_B(PP_B_0),
        .fix_14_16_Out(PP_OUT_0)
    );

//////////////////////////////////////// DSP Instance 1 ////////////////////////
    reg signed [15:0]t_sin_1;
    reg signed [15:0]t_cos_1, inv_cos_1;
    
    wire signed [15:0]T1_OUT_1, T2_OUT_1;
    reg signed [15:0]T1_BUFF_1, T2_BUFF_1;

    goertzel_loop_core GLC_1
    (
        .sys_clk(sys_clk),
        .enable(adc_rdy),
        .start(goert_loop_start),
        .coeff({t_cos_1[14:0], 1'b0}),    // cos * 2
        .data_n(read_bank_data),

        .T1(T1_OUT_1),
        .T2(T2_OUT_1),
        //.read_address(rd_address),
        //.ready(goert_ready),
        .done(goert_loop_cmplt_1)
    );

    reg signed [15:0]PP_A_1, PP_B_1;
    wire signed [15:0]PP_OUT_1;

    dsp_16x16_fix14_16_signed_mul PP_MUL_1
    (
        .sys_clk(sys_clk),
        .dsp_CE(adc_rdy),
        .dsp_A(PP_A_1),
        .dsp_B(PP_B_1),
        .fix_14_16_Out(PP_OUT_1)
    );

////////////////////// END DSP

    reg stall_write;
    reg last_wr_add_msb;    // ovf detect

    reg [4:0]run_ctr;

    initial begin
        oa_state        = IDLE;
        stall_write     = 0;
        wr_address      = 0;
        last_wr_add_msb = 0;
        wr_en_0         = 0;
        rd_en_0         = 0;

        wr_en_1         = 0;
        rd_en_1         = 0;

        goertzel_mag_0  = 0;
        goertzel_mag_1  = 0;
        mag_rdy         = 0;

        bank_select     = 0;
        old_bank_select = 0;

        goert_loop_start = 0;
        
        request_trig    = 0;
        t_sin_0         = 0;
        t_cos_0         = 0;

        t_sin_1         = 0;
        t_cos_1         = 0;

        inv_cos_0       = 0;
        T1_BUFF_0       = 0;
        T2_BUFF_0       = 0;

        PP_A_0          = 0;
        PP_B_0          = 0;

        inv_cos_1       = 0;
        T1_BUFF_1       = 0;
        T2_BUFF_1       = 0;

        PP_A_1          = 0;
        PP_B_1          = 0;

        run_ctr         = 0;
    end


    always @ (posedge sys_clk) begin    // Handle ADC writes
        case (bank_select)
            0: begin            // Write to Bank 0
                if(adc_data_ready) begin
                    wr_en_0 <= 1'b1;
                end
                else begin
                    if(wr_en_0) begin
                        wr_en_0     <= 1'b0;
                        wr_address  <= wr_address + 1;
                        last_wr_add_msb <= wr_address[8];
                    end

                    if(last_wr_add_msb && (wr_address == 0)) begin
                        stall_write <= 1'b1;
                        wr_address  <= wr_address + 1;
                        
                    end

                    if(stall_write) begin
                        stall_write <= 1'b0;
                        bank_select <= 1'b1;
                    end
                    
                end
            end

            1: begin            // Write to Bank 1
                if(adc_data_ready) begin
                    wr_en_1 <= 1'b1;
                end
                else begin
                    if(wr_en_1) begin
                        wr_en_1     <= 1'b0;
                        wr_address  <= wr_address + 1;
                        last_wr_add_msb <= wr_address[8];
                    end

                    if(last_wr_add_msb && (wr_address == 0)) begin
                        stall_write <= 1'b1;
                        wr_address  <= wr_address + 1;
                    end

                    if(stall_write) begin
                        stall_write <= 1'b0;
                        bank_select <= 1'b0;
                    end
                end
            end
        endcase
    end


    always @ (posedge sys_clk) begin    // handle DSP run on bank change select
        old_bank_select <= bank_select;

        case (oa_state)
            IDLE: begin
                mag_rdy <= 1'b0;
                if(bank_chg_detect && (|num_runs)) begin
                    oa_state <= START;
                    //oa_state        <= GET_TRIG;
                    //request_trig    <= 1'b1;
                end
            end

            START: begin
                mag_rdy         <= 1'b0;
                request_trig    <= 1'b1;
                oa_state        <= GET_TRIG_0;
                run_ctr         <= run_ctr + 1;
            end

            GET_TRIG_0: begin
                if(trig_ready) begin
                    t_sin_0         <= sin_in;
                    t_cos_0         <= cos_in;
                    oa_state        <= GTR_STALL_0;
                    //request_trig    <= 1'b1;
                end
                else request_trig    <= 1'b0;
            end

            GTR_STALL_0: begin
                oa_state            <= GET_TRIG_1;
                request_trig        <= 1'b1;
            end

            GET_TRIG_1: begin
                request_trig        <= 1'b0;

                if(trig_ready) begin
                    t_sin_1         <= sin_in;
                    t_cos_1         <= cos_in;
                    oa_state        <= STALL;
                end
            end

            STALL: begin
                
                oa_state <= RUN_BANK_LOOP;
                goert_loop_start <= 1'b1;

                if(bank_select) rd_en_0 <= 1'b1;
                else            rd_en_1 <= 1'b1;

                inv_cos_0 <= ~t_cos_0 + 1;
                inv_cos_1 <= ~t_cos_1 + 1; 
            end

            RUN_BANK_LOOP: begin
                goert_loop_start <= 1'b0;

                if(goert_loop_done) begin
                    oa_state    <= RUN_BANK_PP;
                    T1_BUFF_0   <= T1_OUT_0;
                    T2_BUFF_0   <= T2_OUT_0;

                    T1_BUFF_1   <= T1_OUT_1;
                    T2_BUFF_1   <= T2_OUT_1;

                    rd_en_0 <= 1'b0;
                    rd_en_1 <= 1'b0;
                end
            end
            // Post processing component, use 1 multiplier per channel with multiplexed i/o
            RUN_BANK_PP: begin      // t2 * -cos
                PP_A_0      <= T2_BUFF_0;
                PP_B_0      <= inv_cos_0;

                PP_A_1      <= T2_BUFF_1;
                PP_B_1      <= inv_cos_1;

                oa_state    <= RUN_BANK_PP_1;
            end

            RUN_BANK_PP_1: begin    // t1 = t2 * -cos + t1
                T1_BUFF_0   <= T1_BUFF_0 + PP_OUT_0;
                PP_A_0      <= T2_BUFF_0;
                PP_B_0      <= t_sin_0;

                T1_BUFF_1   <= T1_BUFF_1 + PP_OUT_1;
                PP_A_1      <= T2_BUFF_1;
                PP_B_1      <= t_sin_1;

                oa_state    <= RUN_BANK_PP_2;
            end

            RUN_BANK_PP_2: begin    // setup t1^2
                T2_BUFF_0   <= PP_OUT_0;
                PP_A_0      <= T1_BUFF_0;
                PP_B_0      <= T1_BUFF_0;

                T2_BUFF_1   <= PP_OUT_1;
                PP_A_1      <= T1_BUFF_1;
                PP_B_1      <= T1_BUFF_1;

                oa_state    <= RUN_BANK_PP_3;
            end

            RUN_BANK_PP_3: begin    // setup t2^2
                T1_BUFF_0   <= PP_OUT_0;
                PP_A_0      <= T2_BUFF_0;
                PP_B_0      <= T2_BUFF_0;

                T1_BUFF_1   <= PP_OUT_1;
                PP_A_1      <= T2_BUFF_1;
                PP_B_1      <= T2_BUFF_1;

                oa_state    <= RUN_BANK_PP_4;
            end

            RUN_BANK_PP_4: begin
                goertzel_mag_0  <= PP_OUT_0 + T1_BUFF_0;
                goertzel_mag_1  <= PP_OUT_1 + T1_BUFF_1;
                mag_rdy         <= 1'b1;

                if(run_ctr == num_runs)begin
                    oa_state        <= IDLE;
                    run_ctr         <= 0;
                end
                else begin
                    oa_state    <= START;
                end
            end
        endcase
    end
    
endmodule