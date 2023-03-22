module spi_hardip_top
#(
    parameter BYTE_W = 8
)
(
    //input wire m_clk,
    input wire mosi_pad,
    input wire sck_pad,
    input wire csn_pad,
    output wire miso_pad,
    
    output reg DRDY,
  //  input wire DWRITTEN,

    output reg [(BYTE_W - 1):0]d_recieved,
    input wire [(BYTE_W - 1):0]d_to_send
);

    reg [(BYTE_W-1):0]spi_rx;
    
    reg [(BYTE_W):0]spi_tx;
    
    reg [2:0]clk_ctr;

    //assign miso_pad = (csn_pad) ? 1'b0 : spi_tx[0];
    assign miso_pad = spi_tx[7];

    initial begin
        d_recieved = 0;
        // RP2040 forcing MSB first
        spi_rx = 0;
        
        //spi_tx = d_to_send;
        // Problem child here...
        spi_tx = 0;

        DRDY = 0;

        clk_ctr = 0;
    end

    // Hardcoded mode 0
    always @ (posedge sck_pad) begin
        if(!csn_pad) begin
            spi_rx = spi_rx << 1;
            spi_rx[0] = mosi_pad;
            //spi_rx <= {mosi_pad, spi_rx >> 1};
            clk_ctr = clk_ctr + 1;
            if(clk_ctr == 3'b000) begin
                d_recieved = spi_rx;
                DRDY = 1'b1;
            end
            else DRDY <= 1'b0;
        end
    end

    always @ (negedge sck_pad) begin
        //if(!csn_pad && clk_ctr) begin
        if(!csn_pad) begin
            spi_tx = spi_tx << 1;
        end
        
        if(!clk_ctr) spi_tx <= {1'b0,d_to_send[(BYTE_W - 1):0]};
    end

/*
    always @ (posedge DWRITTEN) begin
        DRDY <= 1'b0;
    end
*/
endmodule