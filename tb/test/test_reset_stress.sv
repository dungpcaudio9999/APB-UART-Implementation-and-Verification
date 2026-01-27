`ifndef TEST_RESET_STRESS_SV
`define TEST_RESET_STRESS_SV

`include "base_test.sv"

class test_reset_stress extends base_test;
  function new();
    super.new("test_reset_stress");
  endfunction

  virtual task configure();
    env.apb_gen.num_transactions = 0;
  endtask
  
  virtual task run();
    apb_transaction cfg_tr, tr;
    uart_transaction uart_tr;
    
    env.run();
    
    // 1. Initial Config
    $display("[TEST_rst] Configuring DUT...");
    cfg_tr = new(); cfg_tr.write=1; cfg_tr.addr=`UART_REG_CONFIG; cfg_tr.wdata=3;
    env.apb_gen2drv_mb.put(cfg_tr);
    #1000;
    
    // 2. Start RX Traffic (Background)
    $display("[TEST_rst] Launching RX Transaction...");
    fork
        begin
            uart_tr = new();
            if (!uart_tr.randomize() with { dir == uart_transaction::RX; delay == 50; }) $fatal("Randomize failed");
            env.uart_gen2drv_mb.put(uart_tr);
        end
    join_none
    
    // 3. Wait until mid-transaction
    #50000; 
    
    // 4. ASSERT RESET (ON-THE-FLY)
    $display("[TEST_rst] *** ASSERTING RESET MID-TRANSACTION ***");
    // Use hierarchical force on the top-level signal
    force tb_top.preset_n = 1'b0; 
    
    #1000;
    release tb_top.preset_n;
    $display("[TEST_rst] Released Reset.");
    
    // 5. Verify Recovery: Can we Config and Send Data again?
    #1000;
    
    // Re-Config (Registers cleared)
    cfg_tr = new(); cfg_tr.write=1; cfg_tr.addr=`UART_REG_CONFIG; cfg_tr.wdata=3;
    env.apb_gen2drv_mb.put(cfg_tr);
    #1000;
    
    // Send Valid Data
    $display("[TEST_rst] Sending Post-Reset Data...");
    uart_tr = new();
    if (!uart_tr.randomize() with { dir == uart_transaction::RX; data == 8'hA5; }) $fatal("Randomize failed");
    env.uart_gen2drv_mb.put(uart_tr);
    
    #150000;
    
    // Read
    tr = new(); tr.write=0; tr.addr=`UART_REG_RXDATA;
    env.apb_gen2drv_mb.put(tr);
    
    #10000;
    $display("[TEST_rst] Finished.");
    $finish;
  endtask
endclass

`endif
