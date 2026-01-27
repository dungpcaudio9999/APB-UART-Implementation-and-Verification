`ifndef TEST_RX_SV
`define TEST_RX_SV

`include "base_test.sv"

// 1a. Define a specific transaction for RX Read is no longer needed with trans_kind, 
// but we keep it or use trans_kind directly. Let's use trans_kind for simplicity in run().

class test_rx extends base_test;
  function new();
    super.new("test_rx");
  endfunction

  virtual task configure();
    // 0. Configure Environment (Verification Side)
    env.uart_cfg.data_width = 8;
    env.uart_cfg.parity_en  = 0;
    env.uart_cfg.stop_bits  = 1;
    
    $display("[TEST_RX] Configuring Verification Environment...");
    
    // 1. Configure Generator
    // We will control generation manually in run()
    // Using trans_kind = RX_READ for the readback phase
    env.apb_gen.blueprint.trans_kind = apb_transaction::RX_READ;
    env.apb_gen.blueprint.trans_kind.rand_mode(0);

    // Disable automatic run
    env.apb_gen.num_transactions = 0; 
  endtask
  
  virtual task run();
    apb_transaction cfg_tr, ctrl_tr;
    
    // 1. Start Environment (Drivers/Monitors/Scoreboard)
    env.run();

    // 2. DUT CONFIGURATION PHASE (Corrected)
    $display("[TEST_RX] Configuring DUT Registers...");
    
    // 2a. Write to UART_REG_CONFIG (Addr 0x08) -> 8N1
    cfg_tr = new("cfg_tr");
    cfg_tr.write = 1; // Explicit write for config
    cfg_tr.addr  = `UART_REG_CONFIG;
    cfg_tr.wdata = 32'h3; // 8N1
    // Important: We must force kind=CONFIG or manually set properties? 
    // Driver doesn't care about kind, it uses write/addr/wdata.
    env.apb_gen2drv_mb.put(cfg_tr);
    #1000;
    
    // 2b. Start TX Removed for Test RX to avoid spurious "Unexpected TX" warnings.
    // Assuming RX is always enabled or doesn't need this bit.
    
    // 3. Main Test Loop: Send 1 Byte -> Wait -> Read 1 Byte
    $display("[TEST_RX] Starting Validated RX Loop (Send -> Read)...");
    
    repeat(20) begin
        // A. Generate and Send 1 UART Byte (Agent -> DUT)
        uart_transaction uart_tr = new();
        uart_tr.c_delay.constraint_mode(0);
        if (!uart_tr.randomize() with { 
            stop_bits == 1; 
            delay inside {[10:20]}; 
            dir == uart_transaction::RX; 
        }) $fatal("Randomization failed in test_rx");
        $display("[TEST_RX] CPU Expected: %h", uart_tr.data);
        env.uart_gen2drv_mb.put(uart_tr);
        
        // B. Wait for Transmission (10 bits * 8.68us = ~87us) + Overhead
        #200000; // 200us
        
        // C. Trigger APB Read (DUT -> CPU)
        // Generator is set to RX_READ in configure()
        env.apb_gen.generate_batch(1);
        
        // D. Wait for APB Read to complete
        #50000;
    end
    
    #10000;
    $display("[TEST_RX] Test Done.");
    $finish;
  endtask

endclass

`endif

