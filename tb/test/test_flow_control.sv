`ifndef TEST_FLOW_CONTROL_SV
`define TEST_FLOW_CONTROL_SV

`include "base_test.sv"

class test_flow_control extends base_test;
  function new();
    super.new("test_flow_control");
  endfunction

  virtual task configure();
    $display("[TEST_FLOW_CONTROL] Configuring for CTS/RTS Check...");
    
    // 1. Enable Auto-Flow Control in Config Reg (if supported) or just test header/pins
    // For this test, we might mix TX writes and verify RTS toggles,
    // or drive CTS and verify TX pauses.
    
    // Let's set up a "Flood" scenario for TX to trigger FIFO full -> RTS check
    env.apb_gen.blueprint.c_default.constraint_mode(0);
    env.apb_gen.blueprint.randomize() with {
        write == 1;
        addr == `UART_REG_TXDATA;
    };
    
    // Send more data than FIFO depth (assume 16 or 32)
    env.apb_gen.num_transactions = 40; 
  endtask
endclass

`endif
