/*
    ProgrammaGull Logic Sandpiper v. Alpha Binary to Decimal 7 Segment Converter

    alignment_shift = how many chars to offset from
        left justification

    If right_align is selected this value will shift
        towards the left instead.
*/

/*
module PGL_Sandpiper_vAlpha_Bin_2_7Seg
#(
    parameter D_W = 8,
    parameter NUM_SEG = 8,
    parameter NUM_CHAR = 8,
    parameter MAX_PRINT_CHARS = 8
)
(
    input sys_clk,
    input en,
    input st_conv,
    input right_align,
    input [($clog2(NUM_CHAR) - 1):0] alignment_shift,
    input [(D_W - 1):0] data,

    output reg [(NUM_SEG - 1):0] SEG_VAL,
    output reg [($clog2(NUM_CHAR) - 1):0] SELECTED_CHAR,
    output reg COMMIT_VALS,
    output reg CONV_DONE
);

    // Up to 32 bits, but really limited to 8 digits so practical max at
    //  26.5 bits
    localparam BASE_10_DIG_CT = (D_W < 2) ? 1 :
                                (D_W < 7) ? 2 :
                                (D_W < 10) ? 3 :
                                (D_W < 14) ? 4 :
                                (D_W < 17) ? 5 :
                                (D_W < 20) ? 6 :
                                (D_W < 24) ? 7 :
                                (D_W < 27) ? 8 :
                                (D_W < 30) ? 9 : 
                                10;

    localparam MAX_B10_DIGITS = (BASE_10_DIG_CT < MAX_PRINT_CHARS) ? 
                                                BASE_10_DIG_CT : MAX_PRINT_CHARS;



    initial begin
        SEG_VAL         = 0;
        SELECTED_CHAR   = 0;
        COMMIT_VALS     = 0;
        CONV_DONE       = 0;
    end


    always @ (sys_clk) begin
        if(en) begin
            case(oa_state)
                IDLE: begin
                    if(st_conv) begin

                    end
                    else begin
                        CONV_DONE   <= 1;
                    end
                end




            endcase
        else begin
            COMMIT_VALS     <= 0;
        end

    end

endmodule

*/