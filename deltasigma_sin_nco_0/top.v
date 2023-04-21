module top
#(
    parameter D_W = 16,
    parameter D_CT = 256,
    parameter D_BITS = 8
)
(
    output wire gpio_37,
    output wire gpio_43
);
// GPIO 23 DAC_OUT
    wire clk_hf;
    SB_HFOSC inthfosc
    (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_hf)
    );
<<<<<<< HEAD
    // 48M / 1 = 48M
=======
    // 48M / 2 = 24M
>>>>>>> 0911d170bf0831fbddcbdc6e10cf19fd06af7da8
    defparam inthfosc.CLKHF_DIV = "0b01";


//    wire clk_lf;
//    SB_LFOSC intlfosc
//    (
//        .CLKLFEN(1'b1),
//        .CLKLFPU(1'b1),
//        .CLKLF(clk_lf)
//    );

    /*
    module SIN_NCO
(
    input clk,
    input wire [15:0]nco_div,
    output reg [(SAMPLE_W - 1):0]nco_out,
    output wire ncoovfsync
);
    */
    reg [15:0]nco_divvy;
    wire [(D_W - 1):0]nco_dat;

    SIN_NCO nco
    (
        .clk(clk_hf),
        .nco_div(nco_divvy),
        .nco_out(nco_dat),
        .ncoovfsync(gpio_37)     // 37
    );

    /*
module fods_mod
(
    input mod_clk,
    input [(DATA_W - 1):0]mod_din,
    output wire mod_dout
)
    */
  
    fods_mod DELSIG
    (
        .mod_clk(clk_hf),
        .mod_din(nco_dat),
        .mod_dout(gpio_43)       // 43
    );
   
   // reg [7:0]int_cl_lf_div;

    initial begin
        //nco_divvy = 188;    // 1khz

        nco_divvy = 16;

       // int_cl_lf_div = 0;
    end

    //always @ (posedge clk_lf) begin
    //    int_cl_lf_div <= int_cl_lf_div + 1;
    //end

/*
    always @ (posedge int_cl_lf_div[5]) begin
        if(nco_divvy < 188 * 2) nco_divvy <= nco_divvy + 1;
        else nco_divvy <= 188;
    end
*/
endmodule