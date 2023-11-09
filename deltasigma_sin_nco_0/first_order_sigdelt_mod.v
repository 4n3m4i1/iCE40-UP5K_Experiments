module fods_mod
#(
    parameter DATA_W = 16
)
(
    input mod_clk,
    input [(DATA_W - 1):0]mod_din,
    output wire mod_dout
);

    reg [(DATA_W):0]mod_accum;

    assign mod_dout = mod_accum[DATA_W];

/*
    dsp_adder dsmodadd(
                        .dsp_clk(mod_clk),
                        .A(mod_din),
                        .carry(mod_dout)
                        );
*/
    initial begin
        //mod_accum = {DATA_W + 1{1'b0}};
        mod_accum = 0;
    end

    always @ (posedge mod_clk) mod_accum <= mod_accum[(DATA_W - 1):0] + mod_din;

endmodule



module dsp_adder
#(
    parameter D_W = 16
)
(
    input dsp_clk,
    input wire [(D_W - 1):0]A,
  //  input wire [(D_W - 1):0]B,
  //  input wire [(D_W - 1):0]C,
  //  input wire [(D_W - 1):0]D,

    output wire carry
);


    SB_MAC16
        #(
        .C_REG(1'b0), 
        .A_REG(1'b0), 
        .B_REG(1'b0), 
        .D_REG(1'b0),
        .TOP_8x8_MULT_REG(1'b0), 
        .BOT_8x8_MULT_REG(1'b0), 
        .PIPELINE_16x16_MULT_REG1(1'b0), 
        .PIPELINE_16x16_MULT_REG2(1'b0),
        .TOPOUTPUT_SELECT(2'b00), 
        .TOPADDSUB_LOWERINPUT(2'b00),
        .TOPADDSUB_UPPERINPUT(1'b0), 
        .TOPADDSUB_CARRYSELECT(2'b00),
        .BOTOUTPUT_SELECT(2'b00), 
        .BOTOUTPUT_SELECT(2'b00),
        .BOTADDSUB_LOWERINPUT(2'b00),
        .BOTADDSUB_UPPERINPUT(2'b00),
        .BOTADDSUB_CARRYSELECT(2'b00),
        .MODE_8x8(1'b0),
        .A_SIGNED(1'b0),
        .B_SIGNED(1'b0)
        ) SB_ADDER_INST
        (
        .CLK(dsp_clk), 
        .CE(1'b1), 
        .A(A), 
        .AHOLD(1'b0),
    //    .B(B),
        .BHOLD(1'b0),
    //    .C(C),
        .CHOLD(1'b0),
    //    .D(D),
        .DHOLD(1'b0),
        .IRSTTOP(1'b0),
        .ORSTTOP(1'b0),
        .OLOADTOP(1'b0),
        .ADDSUBTOP(1'b0),
   //     .Q(),              //
   //     .O(),
        .IRSTBOT(1'b0),
        .ORSTBOT(1'b0), 
        .OLOADBOT(1'b0),
        .ADDSUBBOT(1'b0),
        .OHOLDBOT(1'b0),
        .CI(1'b0),
        .CO(carry),
        .ACCUMCI(1'b0),
        .ACCUMCO(),
        .SIGNEXTIN(1'b0),
        .SIGNEXTOUT()
        );
endmodule