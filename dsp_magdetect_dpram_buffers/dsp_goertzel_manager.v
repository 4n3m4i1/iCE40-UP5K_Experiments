



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
    output reg mag_rdy,

    output reg request_trig,
    input signed [15:0]sin_in,
    input signed [15:0]cos_in,
    // Must be at least 1
    input [4:0]num_runs                 // Number of loops to run. New trig coeff will be requester for each run.
);

    localparam IDLE     = 4'h0;     // Wait for bank change
    localparam START    = 4'h1;     // Rq new trig coeffs
    localparam GET_TRIG = 4'h2;     // Find which bank to run DSP on
    localparam STALL    = 4'h3;     // Find which bank to run DSP on
    localparam RUN_BANK_LOOP    = 4'h4;
    localparam RUN_BANK_PP      = 4'h5;
    localparam RUN_BANK_PP_1    = 4'h6;
    localparam RUN_BANK_PP_2    = 4'h7;
    localparam RUN_BANK_PP_3    = 4'h8;
    localparam RUN_BANK_PP_4    = 4'h9;
    
    

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
    reg signed [15:0]t_sin;
    reg signed [15:0]t_cos, inv_cos;
    
    wire signed [15:0]T1_OUT, T2_OUT;
    reg signed [15:0]T1_BUFF, T2_BUFF;

    wire goert_ready, goert_loop_done;

    goertzel_loop_core GLC_0
    (
        .sys_clk(sys_clk),
        .enable(adc_rdy),
        .start(goert_loop_start),
        .coeff({t_cos[14:0], 1'b0}),    // cos * 2
        .data_n(read_bank_data),

        .T1(T1_OUT),
        .T2(T2_OUT),
        .read_address(rd_address),
        .ready(goert_ready),
        .done(goert_loop_done)
    );


    reg signed [15:0]PP_A, PP_B;
    wire signed [15:0]PP_OUT;

    dsp_16x16_fix14_16_signed_mul PP_MUL
    (
        .sys_clk(sys_clk),
        .dsp_CE(adc_rdy),
        .dsp_A(PP_A),
        .dsp_B(PP_B),
        .fix_14_16_Out(PP_OUT)
    );

    reg stall_write;
    reg last_wr_add_msb;    // ovf detect

    reg [4:0]run_ctr;

    initial begin
        oa_state    = IDLE;
        stall_write = 0;
        wr_address  = 0;
        last_wr_add_msb = 0;
        wr_en_0     = 0;
        rd_en_0     = 0;

        wr_en_1     = 0;
        rd_en_1     = 0;

        goertzel_mag     = 0;
        mag_rdy     = 0;

        bank_select = 0;
        old_bank_select = 0;

        goert_loop_start = 0;
        
        request_trig = 0;
        t_sin = 0;
        t_cos = 0;
        // 100k bin
        //t_sin = 16'h3CC5;
        //t_cos = 16'h1413;

        // 120k bin
        //t_sin = 16'h3F31;
        //t_cos = 16'h03EC;

        inv_cos = 0;
        T1_BUFF = 0;
        T2_BUFF = 0;

        PP_A = 0;
        PP_B = 0;

        run_ctr = 0;
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

                    //if(wr_address == (NUM_SAMPLES - 1)) begin
                    if(last_wr_add_msb && (wr_address == 0)) begin
                        stall_write <= 1'b1;
                        //bank_select <= 1'b1;
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
                    //if(wr_address == (NUM_SAMPLES - 1)) begin
                        stall_write <= 1'b1;
                        //bank_select <= 1'b0;
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
                oa_state        <= GET_TRIG;
                run_ctr         <= run_ctr + 1;
            end

            GET_TRIG: begin
                t_sin           <= sin_in;
                t_cos           <= cos_in;
                
                request_trig    <= 1'b0;
                oa_state        <= STALL;
            end

            STALL: begin
                
                oa_state <= RUN_BANK_LOOP;
                goert_loop_start <= 1'b1;

                if(bank_select) rd_en_0 <= 1'b1;
                else            rd_en_1 <= 1'b1;

                inv_cos <= ~t_cos + 1; 
            end

            RUN_BANK_LOOP: begin
                goert_loop_start <= 1'b0;

                if(goert_loop_done) begin
                    oa_state    <= RUN_BANK_PP;
                    T1_BUFF     <= T1_OUT;
                    T2_BUFF     <= T2_OUT;

                    rd_en_0 <= 1'b0;
                    rd_en_1 <= 1'b0;
                end
            end

            RUN_BANK_PP: begin      // t2 * -cos
                PP_A <= T2_BUFF;
                PP_B <= inv_cos;
                oa_state <= RUN_BANK_PP_1;
            end

            RUN_BANK_PP_1: begin    // t1 = t2 * -cos + t1
                T1_BUFF <= T1_BUFF + PP_OUT;
                PP_A <= T2_BUFF;
                PP_B <= t_sin;

                oa_state <= RUN_BANK_PP_2;
            end

            RUN_BANK_PP_2: begin    // setup t1^2
                T2_BUFF <= PP_OUT;
                PP_A <= T1_BUFF;
                PP_B <= T1_BUFF;

                oa_state <= RUN_BANK_PP_3;
            end

            RUN_BANK_PP_3: begin    // setup t2^2
                T1_BUFF <= PP_OUT;
                PP_A <= T2_BUFF;
                PP_B <= T2_BUFF;

                oa_state <= RUN_BANK_PP_4;
            end

            RUN_BANK_PP_4: begin
                goertzel_mag    <= PP_OUT + T1_BUFF;
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