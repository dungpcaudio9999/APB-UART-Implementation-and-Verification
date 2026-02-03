`ifndef TEST_TX_SV
`define TEST_TX_SV

`include "base_test.sv"

class test_tx extends base_test;
  function new();
    super.new("test_tx");
  endfunction

  virtual task configure();
    // 1. Configure Verification Env (UART Monitor settings)
    env.uart_cfg.data_width = 8;
    env.uart_cfg.parity_en  = 0;
    env.uart_cfg.stop_bits  = 1;
    
    // 2. Setup Generator Blueprint for Data Phase
    env.apb_gen.blueprint.trans_kind = apb_transaction::TX_WRITE;
    env.apb_gen.blueprint.trans_kind.rand_mode(0); 
    
    // 3. Disable Auto-Run of Generator (We will trigger it manually after Config)
    env.apb_gen.num_transactions = 0; 
  endtask

  virtual task run();
    apb_transaction cfg_tr, ctrl_tr, tr;

    $display("[TEST_TX] Starting Execution...");
    
    // A. Start the active components (Drivers, Monitors, Scoreboard)
    env.run();

    // B. DUT CONFIGURATION PHASE
    $display("[TEST_TX] Configuring DUT Registers...");
    
    // B1. Write to UART_REG_CONFIG (Addr 0x08) -> 8N1
    cfg_tr = new("cfg_tr");
    cfg_tr.write = 1;
    cfg_tr.addr  = `UART_REG_CONFIG;
    cfg_tr.wdata = 32'h3; // 8N1
    env.apb_gen2drv_mb.put(cfg_tr);
    #1000;
    
    // C. TRAFFIC GENERATION PHASE (Fill FIFO first)
    // Reduce to 16 to fit standard FIFO depth
    $display("[TEST_TX] Filling TX FIFO with 16 Transactions (incl. Corner Cases)...");
    
    // 1. Send 0x00 (All Zeros)
    tr = new(); 
    tr.write = 1; tr.addr = `UART_REG_TXDATA; tr.wdata = 32'h00;
    env.apb_gen2drv_mb.put(tr);
    
    // 2. Send 0xFF (All Ones)
    tr = new(); 
    tr.write = 1; tr.addr = `UART_REG_TXDATA; tr.wdata = 32'hFF;
    env.apb_gen2drv_mb.put(tr);
    
    // 3. Send remaining 14 random
    env.apb_gen.generate_batch(14);
    #10000; // Wait for APB writes to complete

    // B2. Write to UART_REG_CONTROL (Addr 0x0C) -> Enable TX
    // Now that FIFO has data, we pull the trigger!
    ctrl_tr = new("ctrl_tr");
    ctrl_tr.write = 1;
    ctrl_tr.addr  = `UART_REG_CONTROL;
    ctrl_tr.wdata = 32'h1; // Enable TX
    env.apb_gen2drv_mb.put(ctrl_tr);
    #1000;
    
    // D. Wait for drain
    #2000000; 
    
    $display("[TEST_TX] Finished.");
    $finish;
  endtask

endclass

`endif

