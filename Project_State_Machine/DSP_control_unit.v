// Control unit for N parallel Goertzel for
//  tone detection and production

module dsp_control_unit
#(
    parameter BYTE_W = 8,
    parameter D_W = 16
)
(
    input sys_clk,
 //   input dsp_en,
/*
    input ADC_MISO,
    output wire ADC_MOSI,
    output wire ADC_CS,
    output wire ADC_SCK,

    output reg [7:0]result_byte,
    output reg result_ready_strobe,

    output reg isRX,                 // Has DSP detected a transmission is ongoing

    input [(BYTE_W - 1):0]input_data,
    input TX_requested,             // High when TX fifo has data
    output reg new_input_request    // request new TX fifo data
*/
    output wire [15:0]goert_data,
    output wire goert_indic
);
    // DSP uses the FIX14_16 format
    //  signed 16 bit values with a binary point at
    //  bit 14. This leaves 1 bit beyond the binary point
    //  besides the sign bit
    // For 32 -> 16 bit multiply shifts
    localparam FIX14_16_TOP = 29;
    localparam FIX14_16_BOT = 14;

    localparam SIN_CONST = 16'h3D02;
    localparam COS_CONST = 16'h1354;

/*
    DSP Structure:
        ADC sampling -> bank 0/1 sample memory

        once sample memory is full (8 * 512)
        switch sample mem bank and process the last
        filled bank

        bank N -> n * Goertzel

        if(Goertzel Result indicates transmission occuring){
            Byte reconstruction

            if(byte valid and finished){
                Byte Reconstruction -> store in RX FIFO
            }
        }

    Ingested data is processed across a minimum of 2
        Goertzel Algorithm instances to detect:
            - Carrier Indicator/Data Channel 0
            - Data Channel N
    
    This allows detection of a transmission,
        then reconstruction of a 2 bit symbol per transmission
        interval
*/


/*
Sample Banks should be filled with a 10 bit address, where the MSB indicates
    the bank to be written to. Read data will automatically be accessed from
    the bank that isn't selected (ie not being written to).

Banks will be filled and write addressed from the ADC control module

Banks will be read from and read addressed from the Goertzel State Machine

Goertzel triggers will occur at the end of a sampling period (ie change in MSB
    of write address), the Goertzel memory accesses should complete before the
    next sampling period concludes
*/

/*
module sample_banks
(
    input sys_clk,

    input wire [7:0]d_in,

    input wire write_request,
    input wire [9:0]write_address,
    
    input wire read_request,
    input wire [8:0]read_address,

    output wire current_bank,        // current bank being written
    output wire [7:0]d_out,

    output wire rd_data_valid,
    output wire write_completed
);
*/
    wire [8:0]sbank_addr;
    wire [7:0]sbank_read_data;
/*
    sample_banks SBANKS
    (
        .sys_clk(sys_clk),
        .d_in(8'h00),
        .write_request(1'b0),
        .write_address(10'b0000000000),
        
        .read_request(1'b1),
        .read_address(sbank_addr),
        .d_out(sbank_read_data)
       // .rd_data_valid()
    );
*/



// backup mem strategy
/*
module sample_bram
#(
    parameter SINBITS = 8,
    parameter SINSAMPLES = 511,
    parameter SINSAMPLEBITS = 8
)
(
    input bram_clk,                         // Clock...
    input bram_ce,                          // Read enable
    input [(SINSAMPLEBITS - 1):0]BRAM_ADDR, // 9 bit addressing
    output reg [(SINBITS - 1):0]BRAM_OUT    // 8 bit data out
);
*/
    sample_bram sample_RAM_INST_0
    (
        .bram_clk(sys_clk),
        .bram_ce(1'b1),
        .BRAM_ADDR(sbank_addr),
        .BRAM_OUT(sbank_read_data)
    );



/*
module goertzel_single
#(
    parameter NUM_SAMPLES = 512,
    parameter D_W = 16
)
(
    input dsp_clk,
    input en,
    input run_looping,

    input [(D_W - 1):0]t_sin,
    input [(D_W - 1):0]t_cos,

    input [7:0]sample_data_in,

    output reg [8:0]sample_address,

    output reg goert_done,
    output reg [(D_W - 1):0]goert_mag
);
*/
    reg [15:0]delay;

    reg goert_en, start_goert;

    goertzel_single main_goert
    (
        .dsp_clk(sys_clk),
        .en(goert_en),
        .run_looping(start_goert),
        .t_sin(SIN_CONST),
        .t_cos(COS_CONST),
        .sample_data_in(sbank_read_data),
        .sample_address(sbank_addr),
        .goert_done(goert_indic),
        .goert_mag(goert_data)
    );


    initial begin
        goert_en = 1'b0;
        start_goert = 1'b0;
        delay = {16{1'b0}};
    end

    always @ (posedge sys_clk) begin
        if(!delay[15]) begin
            delay <= delay + 1;
        
            if(delay == 16'h00FF) goert_en <= 1'b1;

            if(delay == 16'h0FFF) start_goert <= 1'b1;
        end
    end

endmodule