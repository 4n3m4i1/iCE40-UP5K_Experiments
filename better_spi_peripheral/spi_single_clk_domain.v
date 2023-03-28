
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
    output reg [(BYTE_W - 1):0]spi_data_rx,
    output reg spi_dreq
);

/*
    SPI Dreq indicates a transfer has completed,
        both new data is ready and new data must be written

*/


    reg [2:0]sck_edge_detector;

    reg [(BYTE_W):0]TX_SHIFT;       // MISO
    reg [(BYTE_W):0]RX_SHIFT;       // MOSI

    reg [2:0]shift_counter;

    assign miso_pad = (csn_pad) ? 1'b0 : TX_SHIFT[7];

    initial begin
        spi_dreq = 1'b0;
        spi_data_rx = {(BYTE_W){1'b0}};

        sck_edge_detector = 3'b000;



        TX_SHIFT = {(BYTE_W + 1){1'b0}};
        RX_SHIFT = {(BYTE_W + 1){1'b0}};

        shift_counter = 0;
    end


    always @ (posedge sys_clk) begin
        if(!csn_pad) begin          // CS Asserted
            sck_edge_detector = {sck_edge_detector[1], sck_edge_detector[0], sck_pad};

            if((sck_edge_detector == 3'b100) ||
                (sck_edge_detector == 2'b011)) begin
                if(sck_pad) begin            // RISING Event
                    RX_SHIFT <= {RX_SHIFT[(BYTE_W - 1):0], mosi_pad};
                  //  RX_SHIFT = RX_SHIFT;
                  //  RX_SHIFT[0] = mosi_pad;
                end

                if(!sck_pad) begin            // FALLING Event
                    TX_SHIFT <= TX_SHIFT << 1;
                    shift_counter = shift_counter + 1;
                end
            
                if(shift_counter == 0) begin
                    spi_data_rx <= RX_SHIFT;
                    spi_dreq <= 1'b1;
                end
            end
        end
        else begin      // CS Deassert
            shift_counter <= 0;
        end

        if(spi_data_written && shift_counter == 0) begin
            TX_SHIFT <= {1'b0, spi_data_to_send};
            //TX_SHIFT <= {spi_data_to_send, 1'b0};
            spi_dreq <= 1'b0;
        end

    end

endmodule