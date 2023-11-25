


module SR_DB
#(
    parameter SYSCLK_FREQ = 24000000,
    parameter DEBOUNCE_DELAY = 0.150
)(
    input       clk,
    input       D,
    output reg  Q
);

    localparam DELAY_CYCLES =   SYSCLK_FREQ * DEBOUNCE_DELAY;
    localparam DELAY_CT_BITS =  $clog2(DELAY_CYCLES);

    reg [(DELAY_CT_BITS - 1):0] delay_ctr;
    reg timeout_indic;

    initial begin
        Q               = 0;
        delay_ctr       = 0;
        timeout_indic   = 0;
    end


    always @ (posedge clk) begin
        if(!timeout_indic && D) begin 
            timeout_indic   <= 1;
            Q               <= 1;
        end

        if(timeout_indic) begin
            Q               <= 0;
            
            if(delay_ctr == DELAY_CYCLES) begin
                timeout_indic   <= 0;
                delay_ctr       <= 0;
            end
            else delay_ctr      <= delay_ctr + 1;
        end

    end


endmodule