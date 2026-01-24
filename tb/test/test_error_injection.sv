`ifndef TEST_ERROR_INJECTION_SV
`define TEST_ERROR_INJECTION_SV

`include "base_test.sv"

class test_error_injection extends base_test;
  function new();
    super.new("test_error_injection");
  endfunction

  virtual task configure();
    $display("[TEST_ERROR] Configuring for Parity Error Injection...");
    
    // 1. Configure the DUT to expect Parity (e.g., Odd)
    // TODO: Need APB Write to CONFIG Reg here.
    
    // 2. Configure UART Agent to send data with WRONG Parity
    // env.uart_gen.blueprint.parity_error = 1;
    
    // 3. Configure APB Gen to Read Status/RXDATA
    env.apb_gen.blueprint.c_default.constraint_mode(0);
    env.apb_gen.blueprint.randomize() with {
        write == 0;
        addr inside {`UART_REG_STATUS, `UART_REG_RXDATA};
    };
    
    env.apb_gen.num_transactions = 20;
  endtask
endclass

`endif
