

module main_state_machine
#(
    parameter BYTE_W = 8
)
(
    input sys_clk,
    input CSN_PAD,
    input SCK_PAD,
    input MOSI_PAD,
    output wire MISO_PAD,


    output reg [(BYTE_W - 1):0]SYSCFG,
    output reg [(BYTE_W - 3):0]COMMCFG,
    input comm_is_RX,
    input comm_is_TX,

    input [(BYTE_W - 1):0]COMM_RX_FIFO_COUNT,
    input [(BYTE_W - 1):0]COMM_TX_FIFO_COUNT
);

    localparam SPI_ACK = 8'hFF;
    localparam ZERO_BYTE = 8'h00;
    localparam RESERVED_FIELD = 8'hFF;

    reg [2:0]spi_valid_write_edge_detect;   // Rising detector for read valid

    wire [5:0]spi_bytes_recieved;
    wire spi_dreq_loopback;             // Always read data on valid
    wire spi_addr_present, spi_data_present;
    wire spi_accepting_writes;

    wire [(BYTE_W - 1):0]RXD_ADDRESS;
    wire [(BYTE_W - 1):0]RXD_DATA;

    reg [(BYTE_W - 1):0]TXD_DATA;

    // Valid Addresses: 0x00, 0x01, 0x03, 0x05, 0x07
    wire valid_address_rqd;
    assign valid_address_rqd = ((RXD_ADDRESS == 8'h00) ||
                                (RXD_ADDRESS[0])) ? 1'b1 : 1'b0;

    spi_single_clk SPI_ADDR_OPTI_0
    (
        .sys_clk(sys_clk),
        .csn_pad(CSN_PAD),
        .sck_pad(SCK_PAD),
        .mosi_pad(MOSI_PAD),
        .miso_pad(MISO_PAD),

        .spi_data_written(spi_dreq_loopback),
        .spi_dreq(spi_dreq_loopback),

        .spi_data_to_send(TXD_DATA),
        .spi_address_rx(RXD_ADDRESS),
        .spi_address_rx_valid(spi_addr_present),

        .spi_data_byte_rx(RXD_DATA),
        .spi_data_byte_rx_valid(spi_data_present),

        .valid_read(spi_accepting_writes),
        .byte_ctr(spi_bytes_recieved)
    );




    initial begin
        spi_valid_write_edge_detect = 0;
        SYSCFG = 0;
        COMMCFG = 0;
        TXD_DATA = {(BYTE_W){1'b0}};
    end

    
    always @ (posedge sys_clk) begin
        spi_valid_write_edge_detect <= {spi_valid_write_edge_detect[1], 
                                        spi_valid_write_edge_detect[0], 
                                        spi_accepting_writes};

        // detected valid write condition
        if(spi_valid_write_edge_detect == 3'b011) begin
        //if(valid_for_write_to_spi && spi_addr_valid) begin
            casez (spi_bytes_recieved)
                // Implicit Garbage on 1st byte sent back
                6'b000000: TXD_DATA <= SPI_ACK;                                     // Send ACK
                6'b000001: TXD_DATA <= { {(BYTE_W - 1){1'b0}}, valid_address_rqd};  // Send Address Valid
                6'b000010: begin
                    if(RXD_ADDRESS[(BYTE_W - 1)]) begin     // Write Command
                        case (RXD_ADDRESS[2:0])
                            1: SYSCFG <= RXD_DATA;
                            3: COMMCFG <= RXD_DATA[5:0];
                        endcase
                    end
                    else begin                              // Read Command
                        case (RXD_ADDRESS[2:0])
                            0:  TXD_DATA <= ZERO_BYTE;
                            1:  TXD_DATA <= SYSCFG;
                            2:  TXD_DATA <= RESERVED_FIELD;
                            3:  TXD_DATA <= {comm_is_TX, comm_is_RX, COMMCFG[5:0]};
                            4:  TXD_DATA <= RESERVED_FIELD;
                            5:  TXD_DATA <= COMM_RX_FIFO_COUNT;
                            6:  TXD_DATA <= RESERVED_FIELD;
                            7:  TXD_DATA <= COMM_TX_FIFO_COUNT;
                        endcase
                    end
                end
                6'b??????: TXD_DATA <= ZERO_BYTE; 
            endcase
        end

    end

endmodule