/*
    ProgrammaGull Logic Sandpiper v. Alpha 7 Segment Display Driver
    11/09/2023
    
    The Sandpiper v. Alpha (from here on out Sandpiper) uses two
    cascaded 74HCS596 serial -> parallel logic chips to expand I/O and drive
    the 8 character 7 segment display. A ~OE logic pin is also available to
    vary the brightness at any given moment of the display.

    Due to the open drain nature of the 75XX596 and high side PNP switching
    a logic 1 in the shift register will turn a common anode (CA) or segment ON.
    (Section 8 in datasheet: a 1 in the register will pull an output low)

    The packet structure is as follows:
    MSB [15:0] LSB
    MSB {[COMMON ANODE[7:0]],[SEGMENT[7:0]]} LSB
    MSB {[CA7 ... CA0],[DP,G,F,E,D,C,B,A]} LSB 

    Dimming is allowed per value, tie externally to some constant if there is no
    need to vary the brightness per character.

    The display segments are arranged as follows:
    (clockwise)
      A
     ---
  F | G | B
     ---
  E | D | C
     ---    . DP
*/

module PGL_Sandpiper_vAlpha_7Seg_Driver
#(
    parameter SEG_CT = 8,                   // Must be power of 2. Don't change!
    parameter CAN_CT = 8,                   // ^^
    parameter DISPLAY_HZ = 800,
    parameter SYSCLK_F = 24000000,
    parameter DIMMING_STEPS = 256,          // Must be power of 2
    parameter SHIFT_CLK_F = 2000000
)
(
    input en,
    input sys_clk,
    input clear_buffer,
    input commit_char,
    input [(SEG_CT - 1):0] SEGMENTS_2_LIGHT,
    input [($clog2(CAN_CT) - 1):0] CHAR_SELECTED,
    input [(DIMMING_REG_W - 1):0] CHAR_BRIGHTNESS,

    output reg  SCLK,
    output reg  DOUT,
    output reg  RCLK,
    output wire OE
);
    localparam RCLK_COMMIT_2_OUTPUT = 1;
    localparam RCLK_CLR             = 0;

    localparam SEG_TIME_HZ  = DISPLAY_HZ * SEG_CT;
    localparam SEG_TIME_CYC = SYSCLK_F / SEG_TIME_HZ;
    localparam SEG_TIME_W   = $clog2(SEG_TIME_CYC);

    localparam SHIFT_CLK_DIV = SYSCLK_F / SHIFT_CLK_F;
    localparam SHIFT_CLK_DIV_W = $clog2(SHIFT_CLK_DIV);

    localparam DIMMING_REG_W = $clog2(DIMMING_STEPS);
    localparam IDX_W        = $clog2(CAN_CT);

    // Display Buffer, Constantly Refreshed to Display
    reg [(SEG_CT - 1):0] display_buffer [0:(CAN_CT - 1)];
    reg [(DIMMING_REG_W - 1):0] brightness_buffer [0:(CAN_CT - 1)];

    // Internal Character Display Time Counter
    reg [(SEG_TIME_W - 1):0] char_time_ctr;

    // Shift Clock Divider, the 596 doesn't care about clk symmetry as long as the pulse is >7ns
    reg [(SHIFT_CLK_DIV_W - 1):0] shift_clk_ctr;
    localparam SCLK_HI  = 1;
    localparam SCLK_LO  = 0;

    // Internal Index of which char is to be lit
    reg [(IDX_W - 1):0] idx;

    reg [1:0]shift_state;
    localparam WAIT     = 2'h0;
    localparam SHIFT    = 2'h1;
    localparam STALL_0  = 2'h2;
    localparam STALL_1  = 2'h3;

    // Output registers, counters, etc..
    localparam DOUT_SHIFT_D_W = SEG_CT + CAN_CT;
    localparam DOUT_SHIFT_CT_W = $clog2(DOUT_SHIFT_D_W);

    reg [(CAN_CT - 1):0] c_anode_sel;
    reg [(DOUT_SHIFT_D_W - 1):0] dout_shift_reg;
    reg [(DOUT_SHIFT_CT_W):0] dout_shift_ctr;

    reg [(DIMMING_REG_W):0] brightness_tgt;     // 1 wider to divide rate by 2
    reg [(DIMMING_REG_W):0] pwm_ctr;

    // Active low, so invert such that on startup
    //  segments are all off.
    reg OUTPUT_ENABLE;
    assign OE = ~OUTPUT_ENABLE;
    localparam OUTPUT_ON    = 1;
    localparam OUTPUT_OFF   = 0;

    reg [1:0]commit_edge_det;
    localparam COMMIT_RISING = 2'b01;

    integer n;
    initial begin
        DOUT            = 0;
        RCLK            = 0;
        SCLK            = 0;
        OUTPUT_ENABLE   = 0;
        char_time_ctr   = 0;
        idx             = 0;
        shift_state     = 0;
        dout_shift_reg  = 0;
        c_anode_sel     = 0;
        dout_shift_ctr  = 0;
        shift_clk_ctr   = 0;
        brightness_tgt  = 0;
        pwm_ctr         = 0;
        commit_edge_det = 0;

        for(n = 0; n < CAN_CT; n = n + 1) begin
            display_buffer[n] = {(SEG_CT){1'b0}};
            brightness_buffer[n] = {(DIMMING_REG_W - 1){1'b0}};
        end
    end


    // Update Display and Brightness Buffer
    always @ (posedge sys_clk) begin
        if(clear_buffer) begin
            for(n = 0; n < CAN_CT; n = n + 1) begin
                display_buffer[n]       <= 0;
                brightness_buffer[n]    <= 0;
            end
        end
        else if(commit_edge_det == COMMIT_RISING) begin
            display_buffer[CHAR_SELECTED]       <= SEGMENTS_2_LIGHT;
            brightness_buffer[CHAR_SELECTED]    <= CHAR_BRIGHTNESS;
        end
        commit_edge_det <= {commit_edge_det[0], commit_char};
    end

    // Run Display Output
    always @ (posedge sys_clk) begin
        if(en) begin
            case (shift_state)
                WAIT: begin
                    if(!c_anode_sel) c_anode_sel <= 8'h01;

                    char_time_ctr <= char_time_ctr + 1;
                    
                    if(char_time_ctr == SEG_TIME_CYC) begin // Light up next char
                        // We can count on rollover since the idx is a power of 2 here
                        dout_shift_reg  <= {c_anode_sel,display_buffer[idx]};
                        dout_shift_ctr  <= 0;
                        char_time_ctr   <= 0;
                        shift_state     <= SHIFT;
                        RCLK            <= RCLK_CLR;
                    end
                end

                SHIFT: begin
                    if(dout_shift_ctr == DOUT_SHIFT_D_W) begin        // Shift new bit out
                        shift_state     <= WAIT;
                        DOUT            <= 0;
                        RCLK            <= RCLK_COMMIT_2_OUTPUT;
                        brightness_tgt  <= {brightness_buffer[idx][(DIMMING_REG_W - 1):0], 1'b0};  // Divide by 2 by expanding ctr
                        idx             <= idx + 1;
                        c_anode_sel     <= {c_anode_sel[(CAN_CT - 2):0], 1'b0};
                    end
                    else begin          // All bits are in shift reg, commit to output, advance to next char
                        DOUT            <= dout_shift_reg[0];
                        //dout_shift_reg  <= {1'b0, dout_shift_reg[DOUT_SHIFT_CT_W - 1:1]};
                        dout_shift_reg  <= dout_shift_reg >> 1;
                        shift_state     <= STALL_0;     // Create output SCLK
                    end
                end
                /*
                    Stall 0 and Stall 1 form a ~50% duty cycle clock at the prescribed rate
                */
                STALL_0: begin
                    if(shift_clk_ctr == (SHIFT_CLK_DIV >> 1)) begin
                        SCLK            <= SCLK_HI;
                        shift_state     <= STALL_1;
                    end
                    else shift_clk_ctr  <= shift_clk_ctr + 1;
                end

                STALL_1: begin
                    if(shift_clk_ctr == SHIFT_CLK_DIV) begin
                        SCLK            <= SCLK_LO;
                        shift_state     <= SHIFT;
                        dout_shift_ctr  <= dout_shift_ctr + 1;
                        shift_clk_ctr   <= 0;
                    end
                    else shift_clk_ctr  <= shift_clk_ctr + 1;
                end
            endcase
            
        end
        else begin
            char_time_ctr   <= 0;
        end
    end

    // Generate Dimming PWM on ~OE
    always @ (posedge sys_clk) begin
        if(en) begin
            if(pwm_ctr == brightness_tgt) OUTPUT_ENABLE <= OUTPUT_OFF;
            else if(pwm_ctr == 0) OUTPUT_ENABLE <= OUTPUT_ON;
            pwm_ctr <= pwm_ctr + 1;
        end
        else begin
            OUTPUT_ENABLE   <= OUTPUT_OFF;
            pwm_ctr         <= 0;
        end
    end
endmodule