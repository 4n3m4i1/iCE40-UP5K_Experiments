
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



// DSP MAC
module dsp_16x16_fix14_16_signed_mac
#(
    parameter D_W = 16
)
(
    input sys_clk,
    input dsp_CE,
    input [(D_W - 1):0]dsp_A,
    input [(D_W - 1):0]dsp_B,
    input [(D_W - 1):0]dsp_C,
    input [(D_W - 1):0]dsp_D,
    output [(D_W - 1):0]fix_14_16_Out
);

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

    // Debug
    //assign fix_14_16_Out = dsp_o[15:0];

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
            .TOPOUTPUT_SELECT(2'b00),           // Top Output: Top Adder no reg
            .TOPADDSUB_LOWERINPUT(2'b10),       // Top Adder in A: Mult upper 16
            .TOPADDSUB_UPPERINPUT(1'b1),        // Top MAC Add input: C
            .TOPADDSUB_CARRYSELECT(2'b10),      // Top Adder CIN <= Bott Adder CO
            .BOTOUTPUT_SELECT(2'b00),           // Bot Output: Bot Adder no reg
            .BOTADDSUB_LOWERINPUT(2'b10),       // Bot Adder in A: Mult Lower 16
            .BOTADDSUB_UPPERINPUT(1'b1),        // Bot Adder in B: D
            .BOTADDSUB_CARRYSELECT(2'b00),      // No Carry in for lower Adder
            .MODE_8x8(0), 
            .A_SIGNED(1), 
            .B_SIGNED(1)
        ) SB_MAC16_inst (
            .CLK(sys_clk), 
            .CE(dsp_CE), 
            .C(dsp_C), 
            .A(dsp_A), 
            .B(dsp_B), 
            .D(dsp_D),
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

// Add/Sub 16x16 signed
module dsp_16x16_fix14_16_signed_adder
#(
    parameter D_W = 16
)
(
    input sys_clk,
    input dsp_CE,
    input signed [(D_W - 1):0]dsp_A,
    input signed [(D_W - 1):0]dsp_B,
    input signed [(D_W - 1):0]dsp_C,
    input signed [(D_W - 1):0]dsp_D,
    output wire [31:0] dsp_o
);

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

    //wire [31:0] dsp_o;
    wire dsp_co;


    //setup the dsp, parameters TOPADDSUB_LOWERINPUT and BOTADDSUB_LOWERINPUT at 2 means we can use MAC operations
    SB_MAC16 
        #(
            .C_REG(1),                          // Reg
            .A_REG(1),                          // Reg
            .B_REG(1),                          // Reg
            .D_REG(1),                          // Reg
            .TOP_8x8_MULT_REG(0), 
            .BOT_8x8_MULT_REG(0),
            .PIPELINE_16x16_MULT_REG1(0),       // no pipeline for now
            .PIPELINE_16x16_MULT_REG2(0), 
            .TOPOUTPUT_SELECT(2'b00),           // Top adder, no reg
            .TOPADDSUB_LOWERINPUT(2'b00),       // Top add lo = A
            .TOPADDSUB_UPPERINPUT(1'b1),        // Top add up = C
            .TOPADDSUB_CARRYSELECT(2'b00),      // 0 Carry
            .BOTOUTPUT_SELECT(2'b00),           // Bot adder, no reg
            .BOTADDSUB_LOWERINPUT(2'b00),       // Bot add lo = B
            .BOTADDSUB_UPPERINPUT(1'b1),        // Bot add up = D
            .BOTADDSUB_CARRYSELECT(2'b00),      // 0 Carry
            .MODE_8x8(0), 
            .A_SIGNED(1), 
            .B_SIGNED(1)
        ) SB_MAC16_inst (
            .CLK(sys_clk), 
            .CE(dsp_CE), 
            .C(dsp_C), 
            .A(dsp_A), 
            .B(dsp_B), 
            .D(dsp_D),
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
        dsp_addsubtop = 0;      // Add A + C
        dsp_addsubbot = 1;      // Sub D - B
        dsp_oloadtop = 0;
        dsp_oloadbot = 0;
        dsp_ci = 0;
    end

    always @ (posedge sys_clk) begin
        // no edge dependencies
    end
endmodule