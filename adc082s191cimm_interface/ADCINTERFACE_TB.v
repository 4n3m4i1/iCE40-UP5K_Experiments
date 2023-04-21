`timescale 1ns/1ps


module adc_interface_testbench();
    reg sys_clk, sck;



    reg miso, en;

    wire [7:0]data_rxd;
    wire rx_done, sdo, csn;
    ADCI_INTERFACE ADC0
    (
        .en(en),
        .sys_clk(sys_clk),
        .ser_clk(sck),
        .SDI(miso),
        .CSN(csn),
        .SDO(sdo),
        .DATA_READ(data_rxd),
        .RX_DONE(rx_done)
    );



    initial begin
        en = 1'b0;
        miso = 1'b0;
        #100;
        en = 1'b1;
        #480;
        miso = 1'b1;
        #120;
        miso = 1'b0;
        #120;
        miso = 1'b1;
        #120;
        miso = 1'b0;
        #120;
        miso = 1'b1;
        #120;
        miso = 1'b0;
        #120;
        miso = 1'b1;
        #120;
        miso = 1'b0;
        #6000;

        $finish;
    end



    initial begin
        $dumpfile("ADCINTERFACE_TB.vcd");
        $dumpvars(0,adc_interface_testbench);
    end

    initial begin       // 8MHz standin
        sck = 0;
        forever begin
            #60;
            sck <= ~sck;
        end
    end

    initial begin       // 48MHz standin
        sys_clk = 0;
        forever begin
            #10;
            sys_clk <= ~sys_clk;
        end
    end

endmodule