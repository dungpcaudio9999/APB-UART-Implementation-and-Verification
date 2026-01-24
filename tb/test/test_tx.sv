`ifndef TEST_TX_SV
`define TEST_TX_SV

`include "base_test.sv"

class test_tx extends base_test;
  function new();
    super.new("test_tx");
  endfunction

  virtual task configure();
    // 1. Configure the UART DUT via APB (Control/Config Registers)
    // We need to inject these setup transactions first.
    // Since our simple generator creates random traffic, we might need a more direct way 
    // to configure the DUT, or assume the generator can be directed.
    // For now, let's use the generator's blueprint to bias generation towards TX Data.
    
    $display("[TEST_TX] Configuring for Basic Transmission Test...");
    
    // Explicitly configure UART Line Control (e.g., 8-bit, No Parity)
    // In a real UVM test, this would be a sequence. Here we cheat slightly by 
    // forcing the first few transactions or relying on defaults.
    // Let's assume defaults are okay for "Basic", or we'll add a config phase later.

    // 2. Direct the Generator to only write to TXFIFO
    env.apb_gen.blueprint.c_default.constraint_mode(0); // Disable generic constraint
    env.apb_gen.blueprint.randomize() with {
        write == 1;
        addr == `UART_REG_TXDATA; // 12'h000
    };
    
    // 3. Set volume
    env.apb_gen.num_transactions = 50; 
  endtask
endclass

`endif

