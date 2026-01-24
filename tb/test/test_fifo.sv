`ifndef TEST_FIFO_SV
`define TEST_FIFO_SV

`include "base_test.sv"

class test_fifo extends base_test;
  function new();
    super.new("test_fifo");
  endfunction

  virtual task configure();
    $display("[TEST_FIFO] Configuring for FIFO Overrun Test...");
    
    // 1. Flood the TX FIFO (TX)
    // Send more writes than the FIFO depth (e.g. 17 writes for 16-deep)
    // and check if the 'pslverr' (APB Slave Error) is asserted or status flag set.
    
    env.apb_gen.blueprint.c_default.constraint_mode(0);
    env.apb_gen.blueprint.randomize() with {
        write == 1;
        addr == `UART_REG_TXDATA;
    };
    
    // Assume FIFO depth is 16
    env.apb_gen.num_transactions = 20; 
  endtask
endclass

`endif
