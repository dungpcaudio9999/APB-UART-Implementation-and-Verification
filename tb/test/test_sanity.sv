`ifndef TEST_SANITY_SV
`define TEST_SANITY_SV

`include "base_test.sv"

class test_sanity extends base_test;
    function new();
        super.new("test_sanity");
    endfunction

    virtual task configure();
        // Sanity: few transactions, maybe directed later
        env.apb_gen.num_transactions = 10;
    endtask
endclass

`endif

