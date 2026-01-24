`ifndef TEST_RX_SV
`define TEST_RX_SV

`include "base_test.sv"

class test_rx extends base_test;
  function new();
    super.new("test_rx");
  endfunction

  virtual task configure();
    $display("[TEST_RX] Configuring for Basic Reception Test...");

    // 1. Direct APB Gen to READ from RXDATA
    env.apb_gen.blueprint.c_default.constraint_mode(0);
    env.apb_gen.blueprint.randomize() with {
        write == 0;
        addr == `UART_REG_RXDATA; // 12'h004
    };
    
    // 2. We also need the UART Agent to send data into the DUT.
    // Since uart_gen is separate, we need to configure it too.
    // Assuming environment has: uart_generator uart_gen;
    // We haven't implemented uart_generator detailed logic yet, but we will set the stage.
    // env.uart_gen.num_transactions = 50; 
    
    env.apb_gen.num_transactions = 50;
  endtask
endclass

`endif

