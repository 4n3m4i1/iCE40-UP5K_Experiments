

module sample_banks
(
    input sys_clk,

    input wire [7:0]d_in,

    input wire write_request,
    input wire [9:0]write_address,
    
    input wire read_request,
    input wire [8:0]read_address,

    output wire current_bank,        // current bank being written
    output wire [7:0]d_out

//    output wire rd_data_valid,
//    output wire write_completed
);
    localparam NUM_SAMPLES = 512;
    localparam NUM_SAMP_BITS = $clog2(NUM_SAMPLES);

    assign current_bank = write_address[9];

/*
If Current bank == 0
    Read from Bank 1
    Write to Bank 0

If Current bank == 1
    Read from bank 0
    write to Bank 1
*/

    wire bank_0_RE;
    wire bank_0_WE;

    wire bank_1_RE;
    wire bank_1_WE;

    assign bank_0_RE = (current_bank) ? read_request : 1'b0;    // Read from other bank
    assign bank_0_WE = (current_bank) ? 1'b0 : write_request;   // Write to selected bank

    assign bank_1_RE = (current_bank) ? 1'b0 : read_request;    // Read from other bank
    assign bank_1_WE = (current_bank) ? write_request : 1'b0;   // WRite to selected bank

    wire [7:0]bank_0_out;
    wire [7:0]bank_1_out;

    assign d_out = (current_bank) ? bank_0_out : bank_1_out;

    //wire bank_0_rd_complete;
    //wire bank_1_rd_complete;

    //wire bank_0_wr_complete;
    //wire bank_1_wr_complete;

    //assign rd_data_valid = (current_bank) ? bank_1_rd_complete : bank_0_rd_complete;

    //assign write_completed = (current_bank) ? bank_0_wr_complete : bank_1_wr_complete;
/*
    implicit_bram_8x512_sample_mem_bank bank_0
    (
        .bram_clk(sys_clk),
        .RE(bank_0_RE),
        .WE(bank_0_WE),
        .rd_address(read_address),
        .wr_address(write_address[8:0]),
        //.rd_dat_ready(bank_0_rd_complete),
        //.write_complete(bank_0_wr_complete),
        .rd_data(bank_0_out),
        .wr_data(d_in)
    );

    implicit_bram_8x512_sample_mem_bank bank_1
    (
        .bram_clk(sys_clk),
        .RE(bank_1_RE),
        .WE(bank_1_WE),
        .rd_address(read_address),
        .wr_address(write_address[8:0]),
        //.rd_dat_ready(bank_1_rd_complete),
        //.write_complete(bank_1_wr_complete),
        .rd_data(bank_1_out),
        .wr_data(d_in)
    );
*/

endmodule


module implicit_bram_8x512_sample_mem_bank
#(
    parameter BYTE_W = 8,
    parameter NUM_SAMPLES = 512,
    parameter NSAMP_BITS = 9
)(
    input wire bram_clk,
    input wire RE,
    input wire WE,

    input wire [(NSAMP_BITS - 1):0] rd_address,
    input wire [(NSAMP_BITS - 1):0] wr_address,

 //   output reg rd_dat_ready,
 //   output reg write_complete,
    output reg [(BYTE_W - 1):0]rd_data,
    //output reg [8:0]rd_data,
    input wire [(BYTE_W - 1):0]wr_data
);

    reg [7:0] bram_contents [0:511];

 //   integer n;

    initial begin
        // Initialize with test sin data
        $readmemh("sample_table_8x512.mem", bram_contents);
        
        rd_data = {(BYTE_W){1'b0}};
/*
        rd_dat_ready = 1'b0;
        write_complete = 1'b0;
*/
    end

    always @ (posedge bram_clk) begin
//        rd_dat_ready <= 1'b0;
//        write_complete <= 1'b0;

        if(RE) begin
            rd_data <= bram_contents[rd_address];
//            rd_dat_ready <= 1'b1;
        end

        if(WE) begin
            bram_contents[wr_address] <= wr_data;
//            write_complete <= 1'b1;
        end

    end

endmodule

/*
module bram_8x512_sample_mem
#(
    parameter BYTE_W = 8,
    parameter NUM_SAMPLES = 512,
    parameter NSAMP_BITS = 9
)
(
    input mem_clk,

    input write_enable,
    input [(NSAMP_BITS - 1):0]write_address,
    input [(BYTE_W - 1):0]write_data,

    input read_enable,
    input [(NSAMP_BITS - 1):0]read_address,
    output [(BYTE_W - 1):0]read_data
);

    SB_RAM512x8 explicit_bram_inst (
        .RDATA(read_data),
        .RADDR(read_address),
        .RCLK(mem_clk),
        .RCLKE(read_enable),
        .RE(read_enable),

        .WADDR(write_address),
        .WCLK(mem_clk),
        .WCLKE(write_enable),
        .WDATA(write_data),
        .WE(write_enable)
    );

endmodule
*/

module sample_bram
#(
    parameter SINBITS = 8,
    parameter SINSAMPLES = 512,
    parameter SINSAMPLEBITS = 9
)
(
    input bram_clk,                         // Clock...
    input bram_ce,                          // Read enable
    input [(SINSAMPLEBITS - 1):0]BRAM_ADDR, // 9 bit addressing
    output reg [(SINBITS - 1):0]BRAM_OUT    // 8 bit data out
);

    
    reg [7:0] data [0 : 511];

    initial begin
        // Read data into memory
        $readmemh("sample_table_8x512.mem", data);
    end

    always @ (posedge bram_clk) begin
        if(bram_ce) BRAM_OUT <= data[BRAM_ADDR];
    end

endmodule