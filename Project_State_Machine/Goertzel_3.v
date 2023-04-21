/*


    Run loop of:

        T1 <= (coeff * T1) + (data[n] + T2)
        T2 <= T1
        n  <= n + 1

    Assume data should be ready on every rising clock
    BRAM is negedge sensitive
*/



module goertzel_core
#(
    parameter D_W = 16,
    parameter SHAMT = 14,
    parameter BYTE_W = 8,
    parameter SAMPLE_W = 8,
    parameter NUM_SAMPLES = 512,
    parameter NUM_SAMPLES_BITS = 9
)
(
    input dsp_clk,
    input [(SAMPLE_W - 1):0]sample_data,
    input [(D_W - 1):0]coeff,
    
    input start,

    output reg [(NUM_SAMPLES_BITS - 1):0]sample_address,
    output reg [(D_W - 1):0]T1_OUT,
    output reg [(D_W - 1):0]T2_OUT,

    // Data is valid while done is high
    output reg done
);
    localparam IS_DONE      = 1'b1;
    localparam NOT_DONE     = 1'b0;

    localparam IDLE         = 3'h0;
    localparam RESET_ALL    = 3'h1;
    localparam RESET_STALL_0= 3'h2;
    localparam RESET_STALL_1= 3'h3;
    localparam RUN_CVT      = 3'h4;
    localparam CLEANUP      = 3'h5;
    localparam SET_DONE     = 3'h6;

    reg [2:0]oa_state;
    reg internal_reset;

    reg signed [(D_W - 1):0]data_buffer;

    reg signed [(D_W - 1):0]coeff_buffer;
    wire signed [(D_W - 1):0]T1, T2, MUL_RES;
    wire signed [(D_W - 1):o]T1_RES, T2_RES;

    assign T1_RES = MUL_RES + T2_RES;
    assign T2_RES = data_buffer - T2;

    dsp_16x16_fix14_16_signed_mul MUL0
    (
        .sys_clk(dsp_clk),
        .dsp_CE(1'b1),
        .dsp_A(coeff_buffer),
        .dsp_B(T1),
        .fix_14_16_Out(MUL_RES)
    );

    dsp_reg_dff T1_REG
    (
        .clk(dsp_clk),
        .rst(internal_reset),
        .D(T1_RES),
        .Q(T1)
    );

    dsp_reg_dff T2_REG
    (
        .clk(dsp_clk),
        .rst(internal_reset),
        .D(T1),
        .Q(T2)
    );


    initial begin
        sample_address = {NUM_SAMPLES_BITS{1'b0}};
        T1_REG = {D_W{1'b0}};
        T2_REG = {D_W{1'b0}};

        data_buffer = {D_W{1'b0}};

        internal_reset = 1'b0;

        done = NOT_DONE;
    end


    always @ (posedge dsp_clk) begin

        case (oa_state)
            IDLE: begin
                if(start) begin
                    oa_state <= RESET_ALL;
                    coeff_buffer <= coeff;
                end
            end
            
            RESET_ALL: begin
                sample_address <= {NUM_SAMPLES_BITS{1'b0}};
                internal_reset <= 1'b1;
                oa_state <= RESET_STALL_0;
            end
            
            // Allow some time for everything to zero out
            RESET_STALL_0:  oa_state <= RESET_STALL_1;
            RESET_STALL_1:  begin
                oa_state <= RUN_CVT;
                data_buffer <= data;
                sample_address <= sample_address + 1;
            end

            RUN_CVT: begin
                if(|sample_address) begin
                    data_buffer <= data;
                    sample_address <= sample_address + 1;
                end
                else oa_state <= CLEANUP;
            end
            
            CLEANUP: begin
                T1_OUT <= T1;
                T2_OUT <= T2;
                oa_state <= SET_DONE;
            end
            
            SET_DONE: begin
                done <= IS_DONE;
                oa_state <= IDLE;
            end
        endcase
    end
endmodule





module dsp_reg_dff
#(
    parameter D_W = 16
)
(
    input clk,
    input rst,
    input [(D_W - 1):0]D,
    output reg [(D_W - 1):0]Q
);


    initial begin
        Q = {D_W{1'b0}};
    end

    always @ (posedge clk) begin
        if(rst) Q <= {D_W{1'b0}};
        else Q <= D;
    end

endmodule