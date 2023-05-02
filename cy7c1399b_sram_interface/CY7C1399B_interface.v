/*

    Raw RAM interface, should be coupled with some control
    unit to manage dataflow

    System ports interface with other modules,
    Pad Interfaces tie straight into IO drivers

    See page 8 of https://rocelec.widen.net/view/pdf/jf0rdbvjnf/CYPRS03402-1.pdf?t.download=true&u=5oefqw
    For truth table
*/
module CY7C1399B_interface
#(
    parameter NUM_ADDRESS_LINES = 10,
    parameter DATA_WIDTH = 8
)
(
    input enable,
    input sys_clk,

    input write_to_sram,
    input read_from_sram,

    // System Ports
    input [(NUM_ADDRESS_LINES - 1):0]w_addr,
    input [(NUM_ADDRESS_LINES - 1):0]r_addr,
    input [(DATA_WIDTH - 1):0]d_in,
    output reg [(DATA_WIDTH - 1):0]d_out,
    output reg data_valid,

    // Pad Interfaces
    inout [(DATA_WIDTH - 1):0]SRAM_DATA,
    output reg [(NUM_ADDRESS_LINES - 1):0]SRAM_ADDRESS,
    output reg SRAM_OE,
    output reg SRAM_WE,
    output reg SRAM_CE
);
    localparam CE_POWERDOWN = 1'b1;
    localparam CE_POWERUP   = 1'b0;

    localparam OE_READ      = 1'b0;
    localparam OE_X         = 1'b1;

    localparam WE_WRITE     = 1'b0;
    localparam WE_X         = 1'b1;

    localparam TRI_Z        = 1'b0;
    localparam TRI_OUT      = 1'b1;

    localparam IDLE         = 3'h0;
    localparam INIT_WRITE   = 3'h1;
    localparam TERM_WRITE   = 3'h2;
    localparam TERM_READ    = 3'h3;
    localparam POWERDOWN_STALL = 3'h4;
    localparam STARTUP_STALL= 3'h5;

    localparam DATA_VALID   = 1'b1;
    localparam DATA_INVALID = 1'b0;

    reg tri_handler;
    reg [(DATA_WIDTH - 1):0]latch_d_in;
    // Handle bidirectional data bus
    assign SRAM_DATA = (tri_handler) ? latch_d_in : {(DATA_WIDTH){1'bZ}};

    wire [(DATA_WIDTH - 1):0]INTERNAL_DATA_READ;
    assign INTERNAL_DATA_READ = SRAM_DATA;

    reg [2:0]oa_state;

    initial begin
        SRAM_CE = CE_POWERUP;
        SRAM_WE = WE_WRITE;
        SRAM_OE = OE_READ;

        latch_d_in  = {(DATA_WIDTH){1'b0}};
        SRAM_ADDRESS = {NUM_ADDRESS_LINES{1'b0}};

        d_out       = {DATA_WIDTH{1'b0}};
        data_valid  = DATA_INVALID;

        oa_state    = IDLE;
    end


    //always @ (posedge sys_clk or negedge sys_clk) begin
    always @ (posedge sys_clk) begin
        case (oa_state)
            IDLE: begin
                if(sys_clk) begin
                    if(enable)  SRAM_CE <= CE_POWERUP;          // Gate enable in IDLE state as an enable falling mid read may corrupt data
                    else begin
                        SRAM_CE     <= CE_POWERDOWN;
                        oa_state    <= POWERDOWN_STALL;
                    end

                    //if(enable)  SRAM_ADDRESS <= d_addr;

                    if(read_from_sram) begin                    // INit read cycle
                        SRAM_WE         <= WE_X;
                        SRAM_ADDRESS    <= r_addr;
                        oa_state        <= TERM_READ;
                    end
                    else if(write_to_sram) begin    // Writes handled as Write Cycle No. 3 (!WE Controlled, !OE Low)
                        latch_d_in      <= d_in;
                        SRAM_WE         <= WE_WRITE;            // tsa = 0ns
                        SRAM_ADDRESS    <= w_addr;
                        oa_state        <= INIT_WRITE;
                    end
                    else begin
                        SRAM_WE         <= WE_X;
                        tri_handler     <= TRI_Z;
                        data_valid      <= DATA_INVALID;
                    end
                end
            end

            INIT_WRITE: begin                       // Writes handled as Write Cycle No. 3 (!WE Controlled, !OE Low)
                tri_handler         <= TRI_OUT;     // Commit changes to RAM, delay in states should avoid bus contention
                oa_state            <= TERM_WRITE;
            end
            TERM_WRITE: begin                       // Writes handled as Write Cycle No. 3 (!WE Controlled, !OE Low)
                SRAM_WE             <= WE_X;
                tri_handler         <= TRI_Z;
                oa_state            <= IDLE;
            end
            TERM_READ: begin                        // Reads handled as Read Cycle No. 1 (Always active unless CE high)
                data_valid          <= DATA_VALID;
                d_out               <= INTERNAL_DATA_READ;
                oa_state            <= IDLE;
            end

            POWERDOWN_STALL: begin                  // Handle shutdown cases
                if(enable) oa_state <= STARTUP_STALL;
                SRAM_CE             <= CE_POWERUP;
            end

            STARTUP_STALL: if(enable) oa_state <= IDLE;   // Synchronize idle being valid on next rising edge
        endcase
    end
endmodule