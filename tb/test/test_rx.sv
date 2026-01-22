`ifndef TEST_RX_SV
`define TEST_RX_SV

`include "base_test.sv"

class test_rx extends base_test;
    function new();
        super.new("test_rx");
    endfunction

    virtual task configure();
    // Configure scenario that exercises UART RX path via uart_driver
    // TODO: add constraints / sequence on uart_gen2drv_mb if needed
    endtask
endclass

`endif

