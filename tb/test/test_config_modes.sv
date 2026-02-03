`ifndef TEST_CONFIG_MODES_SV
`define TEST_CONFIG_MODES_SV

`include "base_test.sv"

class test_config_modes extends base_test;
  function new();
    super.new("test_config_modes");
  endfunction

  virtual task configure();
    // Disable auto-gen
    env.apb_gen.num_transactions = 0;
  endtask
  
  virtual task run();
    apb_transaction cfg_tr, apb_read_tr;
    uart_transaction uart_tr;
    logic [1:0] data_modes[4] = '{0, 1, 2, 3}; // 0=5bit, 1=6bit, 2=7bit, 3=8bit
    int data_lens[4] = '{5, 6, 7, 8};
    bit [7:0] mask;
    
    env.run();
    
    foreach(data_modes[i]) begin
        int mode = data_modes[i];
        int len  = data_lens[i];
        
        // Calculate mask (e.g. 5 bits -> 0x1F)
        mask = (1 << len) - 1;
        
        $display("[TEST_CFG] Testing Data Width: %0d bits...", len);
        
        // 1. Config Testbench Env (Driver/Monitor/Coverage)
        // Update BEFORE APB Write so coverage samples new values
        env.uart_cfg.data_width = len;

        // 2. Config DUT Config Reg
        // [1:0] = Mode
        cfg_tr = new(); cfg_tr.write=1; cfg_tr.addr=`UART_REG_CONFIG; cfg_tr.wdata={30'b0, mode[1:0]};
        env.apb_gen2drv_mb.put(cfg_tr);
        #1000;
        
        // 3. Send Data (Agent -> DUT)
        // We must ensure generated data fits the width to avoid Scoreboard Mismatch
        // (Since Driver/Monitor will truncate, but Scoreboard compares original object)
        uart_tr = new();
        if (!uart_tr.randomize() with {
            data <= mask; 
            delay inside {[10:20]};
            dir == uart_transaction::RX;
        }) $fatal("Randomize failed");
        
        $display("[TEST_CFG] Sending: 0x%h (Mask: 0x%h)", uart_tr.data, mask);
        env.uart_gen2drv_mb.put(uart_tr);
        
        // 4. Wait for processing
        #200000;
        
        // 5. Read from APB
        apb_read_tr = new(); apb_read_tr.write=0; apb_read_tr.addr=`UART_REG_RXDATA;
        env.apb_gen2drv_mb.put(apb_read_tr);
        
        #50000;
    end


    // ---------------------------------------------
    // Part 2: Test 2 Stop Bits
    // ---------------------------------------------
    $display("[TEST_CFG] Testing 2 Stop Bits...");
    
    // 1. Config Env
    env.uart_cfg.data_width = 8;
    env.uart_cfg.stop_bits  = 2;

    // 2. Config DUT: 8-bit (3), 2 Stop (Bit 2=1) -> 0x7
    // [1:0]=11, [2]=1. 111 = 7.
    cfg_tr = new(); cfg_tr.write=1; cfg_tr.addr=`UART_REG_CONFIG; cfg_tr.wdata=32'h7;
    env.apb_gen2drv_mb.put(cfg_tr);
    #1000;
    
    // 3. Send Data
    uart_tr = new();
    if (!uart_tr.randomize() with {
        dir == uart_transaction::RX;
    }) $fatal("Randomize failed");
    env.uart_gen2drv_mb.put(uart_tr);
    
    #200000;
    
    // 4. Read
    apb_read_tr = new(); apb_read_tr.write=0; apb_read_tr.addr=`UART_REG_RXDATA;
    env.apb_gen2drv_mb.put(apb_read_tr);
    
    #50000;
    
    // ---------------------------------------------
    // Part 3: Test Parity Odd
    // ---------------------------------------------
    $display("[TEST_CFG] Testing Parity Odd...");
    
    // 1. Config Env
    env.uart_cfg.data_width = 8;
    env.uart_cfg.stop_bits  = 1;
    env.uart_cfg.parity_en  = 1;
    env.uart_cfg.parity_type = 1; // Odd

    // 2. Config DUT: 8-bit (3), 1 Stop (0), Parity En (1), Parity Odd (1)
    // [1:0]=11 (3)
    // [2]  = 0
    // [3]  = 1 (Enable)
    // [4]  = 1 (Odd)
    // Total: 1_1011 = 0x1B
    cfg_tr = new(); cfg_tr.write=1; cfg_tr.addr=`UART_REG_CONFIG; cfg_tr.wdata=32'h1B;
    env.apb_gen2drv_mb.put(cfg_tr);
    #1000;
    
    // 3. Send Data
    uart_tr = new();
    if (!uart_tr.randomize() with {
        dir == uart_transaction::RX;
    }) $fatal("Randomize failed");
    env.uart_gen2drv_mb.put(uart_tr);
    
    #200000;
    
    // 4. Read (Optional, scoreboard checks it)
    apb_read_tr = new(); apb_read_tr.write=0; apb_read_tr.addr=`UART_REG_RXDATA;
    env.apb_gen2drv_mb.put(apb_read_tr);

    #50000;
    $finish;
  endtask
endclass

`endif
