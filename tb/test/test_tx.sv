`ifndef TEST_TX_SV
`define TEST_TX_SV

`include "base_test.sv"

class test_tx extends base_test;
    function new();
        super.new("test_tx");
    endfunction

    virtual task configure();
        // Configure generator for many TX writes
        env.apb_gen.num_transactions = 100;
        // TODO: constrain to TXDATA writes
    endtask
endclass

`endif

