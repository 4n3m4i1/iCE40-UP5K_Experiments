


module top
#(
    parameter BYTE_W = 8
)
(
    input  wire gpio_20,    // GLobal clk ext in
    output wire gpio_3
);

    reg [11:0]ctr;

    //assign gpio_23 = (!ctr) ? 1 : 0;

    reg outval;

    assign gpio_3 = outval;

    initial begin
        ctr = 0;
        outval = 0;
    end

/*
    // 115.66 MHz max
    always @ (posedge gpio_20) begin
        ctr <= ctr + 1;
    end
*/

    always @ (posedge gpio_20) begin
        ctr <= ctr + 1;
        if(!ctr) outval <= !outval;
        end

endmodule