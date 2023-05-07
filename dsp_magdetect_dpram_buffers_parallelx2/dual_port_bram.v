


module dual_port_bram_8x512
#(
    parameter D_W = 8,
    parameter NUM_SAMPLES = 512,
    parameter NS_BITS = 9
)
(
    input wire clk,

    input wire rd_enable,
    input wire wr_enable,

    input wire [(NS_BITS - 1):0]rd_address,
    input wire [(NS_BITS - 1):0]wr_address,

    input wire [(D_W - 1):0]wr_data_in,

    output reg [(D_W - 1):0]rd_data_out
);



    reg [(D_W - 1):0] bram_contents [0:(NUM_SAMPLES - 1)];

    integer n;
    initial begin
        for(n = 0; n < NUM_SAMPLES; n = n + 1) begin
            bram_contents[n] = 8'h01;
        end
    end


    always @ (posedge clk) begin
        if(wr_enable) begin
            bram_contents[wr_address] <= wr_data_in;
        end

        if(rd_enable) begin
            rd_data_out <= bram_contents[rd_address];
        end
    end

endmodule