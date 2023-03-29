/*
    Single clock domain SPI peripheral

*/
module top
#(
    parameter BYTE_W = 8
)
(
    input wire gpio_23,         // SCK
    input wire gpio_25,         // ~cs
    input wire gpio_26,         // MOSI
    output wire gpio_27,        // MISO

    output wire led_green,
    output wire led_blue
);

    wire clk_24Mhz;             // Will be inferred to global clk
    SB_HFOSC inthfosc(
        .CLKHFEN(1'b1),     // enable output
        .CLKHFPU(1'b1),     // Turn on OSC
        .CLKHF(clk_24Mhz)
    );
    defparam inthfosc.CLKHF_DIV = "0b01";
    // 42M / 2 = 24M

/*
module spi_single_clk
#(
    parameter BYTE_W = 8
)
(
    input sys_clk,

    input csn_pad,
    input sck_pad,
    input mosi_pad,
    output wire miso_pad,

    input spi_data_written,
    input [(BYTE_W - 1):0]spi_data_to_send,
    output reg [(BYTE_W - 1):0]spi_address_rx,
    output reg [(BYTE_W - 1):0]spi_data_byte_rx,
    output reg spi_address_rx_valid,
    output reg spi_data_byte_rx_valid,

    output reg spi_dreq,
    output reg valid_read
);
*/

    reg [2:0]valid_write_edge_detect;

    wire loopback_sig;

    reg [7:0]loopback_data;

    wire [7:0]spi_addr, spi_data;

    wire [5:0]byte_ct_recieved;

    wire valid_for_write_to_spi;

    assign led_green = (spi_addr == 8'h02) ? 1'b0 : 1'b1;
    assign led_blue = (spi_addr == 8'hAA) ? 1'b0 : 1'b1;

    wire valid_address_rqd, spi_addr_valid, spi_data_valid;

    assign valid_address_rqd = (spi_addr > 0) ? 1'b1 : 1'b0;

    spi_single_clk SPI0_inst
    (
        .sys_clk(clk_24Mhz),
        .csn_pad(gpio_25),
        .sck_pad(gpio_23),
        .mosi_pad(gpio_26),
        .miso_pad(gpio_27),

        .spi_data_written(loopback_sig),
        .spi_dreq(loopback_sig),

        .spi_data_to_send(loopback_data),
        .spi_address_rx(spi_addr),
        .spi_data_byte_rx(spi_data),

        .spi_address_rx_valid(spi_addr_valid),
        .spi_data_byte_rx_valid(spi_data_valid),

        .valid_read(valid_for_write_to_spi),
        .byte_ctr(byte_ct_recieved)
    );

    initial begin
        loopback_data = 8'h55;
        valid_write_edge_detect = 0;
    end

    always @ (posedge clk_24Mhz) begin
        valid_write_edge_detect <= {valid_write_edge_detect[1], valid_write_edge_detect[0], valid_for_write_to_spi};

        // detected valid write condition
        if(valid_write_edge_detect == 3'b011) begin
        //if(valid_for_write_to_spi && spi_addr_valid) begin
            casez (byte_ct_recieved)
                6'b000000: loopback_data <= 8'hFF;
                6'b000001: loopback_data <= { {(7){1'b0}}, valid_address_rqd};
                6'b000010: loopback_data <= spi_addr;
                6'b??????: loopback_data <= {(BYTE_W){1'b0}}; 
            endcase
        end

    end

endmodule