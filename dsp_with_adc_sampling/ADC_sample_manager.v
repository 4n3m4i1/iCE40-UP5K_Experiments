/*
    Sample Banks Manager

    There are 2 sample banks 0 and 1 that can be
        in one of 2 modes:
        - Reading/Working Bank
        - Writng Bank

    These banks alternate their mode once a full read
    of NUM_SAMPLES has completed.

    In this configuration NUM_SAMPLES = 512

    Once a sample bank is full all writes will
        be entered into the next bank, and processing is
        begun on the bank that was just filled

    Writes are committed via a strobe,
    Reads should be initiated on a change in current_read_bank

    Any read processing must complete before the bank swap
*/


/*
    Sample manager 2, hopefully this works..
*/
module sample_fifo
#(
    parameter BYTE_W = 8,
    parameter D_W = 16,
    parameter SHAMT = 14,
    parameter NUM_SAMPLES = 512,
    parameter SAMPLE_W = 8,
    parameter SAMPLE_BITS = 9
)
(
    input en,
    input sys_clk,

    input wire input_data_rdy,                   // Write to FIFO bank
    input wire [(SAMPLE_W - 1):0]input_data,

    input wire  [(SAMPLE_BITS - 1):0]read_address,
    output wire [(SAMPLE_W - 1):0]read_data,

    output wire current_bank
);

    wire current_write_bank;
    // 1 extra bit such that the 2 banks can be multiplexed
    reg [(SAMPLE_BITS):0]internal_wr_addr;
    reg [(SAMPLE_W - 1):0]internal_wr_data;

    // Use MSB to indicate which bank we are writing to
    assign current_write_bank = internal_wr_addr[SAMPLE_BITS];

    assign current_bank = current_write_bank;

    wire [(SAMPLE_W - 1):0]bank_0_read, bank_1_read;

    assign read_data = (current_write_bank) ? bank_0_read : bank_1_read;

    implicit_bram_8x512_sample_mem_bank BANK0__
    (
        .WCLK(~sys_clk),
        .RCLK(~sys_clk),
        .RE(!current_write_bank & en),
        .WE(current_write_bank & en),

        .rd_address(read_address),
        .wr_address(internal_wr_addr[(SAMPLE_BITS - 1):0]),
        .rd_data(bank_0_read),
        .wr_data(internal_wr_data)
    );

    implicit_bram_8x512_sample_mem_bank BANK1__
    (
        .RCLK(~sys_clk),
        .WCLK(~sys_clk),
        .RE(current_write_bank & en),
        .WE(!current_write_bank & en),

        .rd_address(read_address),
        .wr_address(internal_wr_addr[(SAMPLE_BITS - 1):0]),
        .rd_data(bank_1_read),
        .wr_data(internal_wr_data)
    );

    initial begin
        internal_wr_addr = 0;
        internal_wr_data = 0;
    end

    always @ (posedge sys_clk) begin
        if(input_data) begin
            internal_wr_addr <= internal_wr_addr + 1;
            internal_wr_data <= input_data;
        end
    end
endmodule


// Sample bank module
module implicit_bram_8x512_sample_mem_bank
#(
    parameter BYTE_W = 8,
    parameter NUM_SAMPLES = 512,
    parameter NSAMP_BITS = 9
)(
    input wire WCLK,
    input wire RCLK,
    input wire RE,
    input wire WE,

    input wire [(NSAMP_BITS - 1):0] rd_address,
    input wire [(NSAMP_BITS - 1):0] wr_address,


    output reg [(BYTE_W - 1):0]rd_data,
    input wire [(BYTE_W - 1):0]wr_data
);

    reg [(BYTE_W - 1):0] bram_contents [0:(NUM_SAMPLES - 1)];

    integer n;
    initial begin
        //for(n = 0; n < NUM_SAMPLES; n = n + 1) begin
        //    bram_contents[n] <= 8'h00;
        //end
        //bram_contents[0] <= 255;

        $readmemh("bram_zeroes.mem", bram_contents);

        //rd_data = {(BYTE_W){1'b0}};
    end

    always @ (posedge RCLK) begin
        if(RE) begin
            rd_data <= bram_contents[rd_address];
        end
    end

    always @ (posedge WCLK) begin
        if(WE) begin
            bram_contents[wr_address] <= wr_data;
        end
    end

endmodule