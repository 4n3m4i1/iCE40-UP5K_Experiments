



module sample_manager
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

    output reg [16:0]adc_sum,
    output reg sum_rdy
);

    localparam IDLE     = 3'h0;
    localparam COLLECT  = 3'h1;
    localparam SUM      = 3'h2;
    localparam CLEANUP  = 3'h3;

    reg [2:0]oa_state;

    reg wr_en, rd_en;

    reg [(NS_BITS - 1):0]wr_address;
    reg [(NS_BITS - 1):0]rd_address;

    wire [(B_W - 1):0]rd_dat;

    dual_port_bram_8x512 DPRAM0
    (
        .clk(!sys_clk),
        .rd_enable(rd_en),
        .wr_enable(wr_en),

        .rd_address(rd_address),
        .wr_address(wr_address),

        .wr_data_in(adc_data_in),
        .rd_data_out(rd_dat)
    );


    initial begin
        oa_state    = IDLE;
        wr_address  = 0;
        rd_address  = 0;
        wr_en       = 0;
        rd_en       = 0;
        adc_sum     = 0;
        sum_rdy     = 0;
    end


    always @ (posedge sys_clk) begin

        case (oa_state)
            IDLE: begin
                sum_rdy         <= 0;

                if(adc_rdy) begin
                    wr_address  <= {NS_BITS{1'b0}};
                    rd_address  <= {NS_BITS{1'b0}};
                    wr_en       <= 0;
                    rd_en       <= 0;
                    adc_sum     <= 0;
                    oa_state    <= COLLECT;
                end
            end

            COLLECT: begin
                if(adc_data_ready) begin
                    wr_en <= 1'b1;
                end
                else begin
                    if(wr_en) begin
                        wr_en       <= 1'b0;
                        wr_address  <= wr_address + 1;
                    end

                    if(wr_address == (NUM_SAMPLES - 1)) begin
                        oa_state    <= SUM;
                        rd_en       <= 1'b1;
                    end
                end
            end

            SUM: begin
                adc_sum <= adc_sum + rd_dat;
                rd_address <= rd_address + 1;

                if(rd_address == (NUM_SAMPLES - 1)) begin
                    oa_state    <= CLEANUP;
                    rd_en       <= 1'b0;
                end
            end

            CLEANUP: begin
                sum_rdy         <= 1;
                oa_state        <= IDLE;
            end
        endcase
    end
endmodule