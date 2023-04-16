module nco_w_phase_in
#(
    parameter NCO_ADDR_BITS = 8
)
(
    input sys_clk,
    input nco_en,

    input [15:0]nco_divider,


    output reg [(NCO_ADDR_BITS - 1):0]addr_out
);

    localparam MIN_DIVIDER = 8;

    reg [15:0]nco_accum;

    initial begin
        addr_out = 8'h00;
        nco_accum = {16{1'b0}};
    end


    always @ (posedge sys_clk) begin
        if(nco_en) begin        
            // Lowest potential output is like 4Hz
            nco_accum <= nco_accum + 1;
            if(nco_accum >= nco_divider) begin
                addr_out <= addr_out + 1;
                nco_accum <= {16{1'b0}};
            end
            
        end
        else nco_accum <= {16{1'b0}};
       
    end

endmodule