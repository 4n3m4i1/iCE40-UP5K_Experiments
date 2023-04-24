module dsp_16x16_fix14_16_signed_mul
#(
    parameter D_W = 16
)
(
    input sys_clk,
    input dsp_CE,
    input [(D_W - 1):0]dsp_A,
    input [(D_W - 1):0]dsp_B,
    output [(D_W - 1):0]fix_14_16_Out
);



    reg [(D_W - 1):0] dsp_c;
    reg [(D_W - 1):0] dsp_d;
    reg dsp_irsttop;
    reg dsp_irstbot;
    reg dsp_orsttop;
    reg dsp_orstbot;
    reg dsp_ahold;
    reg dsp_bhold;
    reg dsp_chold;
    reg dsp_dhold;
    reg dsp_oholdtop;
    reg dsp_oholdbot;
    reg dsp_addsubtop;
    reg dsp_addsubbot;
    reg dsp_oloadtop;
    reg dsp_oloadbot;
    reg dsp_ci;

    wire [31:0] dsp_o;
    wire dsp_co;

    // Fix 14 16 format
    assign fix_14_16_Out = dsp_o[29:14];

    //setup the dsp, parameters TOPADDSUB_LOWERINPUT and BOTADDSUB_LOWERINPUT at 2 means we can use MAC operations
    SB_MAC16 
        #(
            .C_REG(0),                          // unregistered inputs
            .A_REG(0), 
            .B_REG(0), 
            .D_REG(0), 
            .TOP_8x8_MULT_REG(0), 
            .BOT_8x8_MULT_REG(0),
            .PIPELINE_16x16_MULT_REG1(0),       // no pipeline for now
            .PIPELINE_16x16_MULT_REG2(0), 
            .TOPOUTPUT_SELECT(2'b11),           // 16x16 mult
            .TOPADDSUB_LOWERINPUT(0),           // bypassed accum
            .TOPADDSUB_UPPERINPUT(0),           // bypassed accum
            .TOPADDSUB_CARRYSELECT(0),          // bypassed
            .BOTOUTPUT_SELECT(2'b11),           // 16x16 mult
            .BOTADDSUB_LOWERINPUT(0),           // bypassed accum
            .BOTADDSUB_UPPERINPUT(0),           // bypassed accum
            .BOTADDSUB_CARRYSELECT(0),          // bypassed
            .MODE_8x8(0), 
            .A_SIGNED(1), 
            .B_SIGNED(1)
        ) SB_MAC16_inst (
            .CLK(sys_clk), 
            .CE(dsp_CE), 
            .C(dsp_c), 
            .A(dsp_A), 
            .B(dsp_B), 
            .D(dsp_d),
            .IRSTTOP(dsp_irsttop), 
            .IRSTBOT(dsp_irstbot), 
            .ORSTTOP(dsp_orsttop), 
            .ORSTBOT(dsp_orstbot),
            .AHOLD(dsp_ahold), 
            .BHOLD(dsp_bhold), 
            .CHOLD(dsp_chold), 
            .DHOLD(dsp_dhold), 
            .OHOLDTOP(dsp_oholdtop), 
            .OHOLDBOT(dsp_oholdbot),
            .ADDSUBTOP(dsp_addsubtop), 
            .ADDSUBBOT(dsp_addsubbot), 
            .OLOADTOP(dsp_oloadtop), 
            .OLOADBOT(dsp_oloadbot),
            .CI(dsp_ci), 
            .O(dsp_o), 
            .CO(dsp_co)
        );

    initial begin
        dsp_c = 0;
        dsp_d = 0;
        dsp_irsttop = 0;
        dsp_irstbot = 0;
        dsp_orsttop = 0;
        dsp_orstbot = 0;
        dsp_ahold = 0;
        dsp_bhold = 0;
        dsp_chold = 0;
        dsp_dhold = 0;
        dsp_oholdtop = 0;
        dsp_oholdbot = 0;
        dsp_addsubtop = 0;
        dsp_addsubbot = 0;
        dsp_oloadtop = 0;
        dsp_oloadbot = 0;
        dsp_ci = 0;
    end

    always @ (posedge sys_clk) begin
        // no edge dependencies
    end
endmodule