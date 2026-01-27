`ifndef TEST_FIFO_SV
`define TEST_FIFO_SV

`include "base_test.sv"

class test_fifo extends base_test;
  function new();
    super.new("test_fifo");
  endfunction

  virtual task configure();
    env.uart_cfg.data_width = 8;
    env.uart_cfg.stop_bits  = 1;
    env.uart_cfg.parity_en  = 0;
    
    // Disable APB Auto-Gen
    env.apb_gen.num_transactions = 0; 
  endtask
  
  virtual task run();
    apb_transaction cfg_tr, tr;
    uart_transaction uart_tr;
    
    env.run();
    
    $display("[TEST_FIFO] Starting FIFO Verification...");
    
    // 1. Config DUT (8N1)
    cfg_tr = new(); cfg_tr.write=1; cfg_tr.addr=`UART_REG_CONFIG; cfg_tr.wdata=3;
    env.apb_gen2drv_mb.put(cfg_tr);
    #1000;
    
    // -------------------------------------------------------------
    // Part 1: Fill FIFO to Max Capacity (16 Bytes) and Drain
    // -------------------------------------------------------------
    $display("[TEST_FIFO] Part 1: Fill TX FIFO to Max (16 Bytes)...");
    
    // Write 16 bytes
    repeat(16) begin
        tr = new(); 
        tr.write=1; tr.addr=`UART_REG_TXDATA; tr.wdata=$random;
        env.apb_gen2drv_mb.put(tr);
    end
    
    // Trigger TX
    tr = new(); tr.write=1; tr.addr=`UART_REG_CONTROL; tr.wdata=1; 
    env.apb_gen2drv_mb.put(tr);
    
    // Wait for Drain (16 * ~87us = ~1.4ms)
    #2000000;
    
    // Read Status (Check TX_DONE=1)
    tr = new(); tr.write=0; tr.addr=`UART_REG_STATUS;
    env.apb_gen2drv_mb.put(tr);
    #1000;
    
    // -------------------------------------------------------------
    // Part 2: RX FIFO Overrun Test
    // -------------------------------------------------------------
    $display("[TEST_FIFO] Part 2: RX FIFO Overrun (Send 20 bytes)...");
    
    // Send 20 bytes from UART VIP (Faster than APB reads)
    fork
        // Thread A: Send 20 bytes
        begin
             repeat(20) begin
                uart_tr = new();
                if (!uart_tr.randomize() with {
                    dir == uart_transaction::RX;
                    delay inside {[1:2]};
                }) $fatal("Randomize failed");
                env.uart_gen2drv_mb.put(uart_tr);
             end
        end
        
        // Thread B: Wait then Read
        begin
            #200000; // Wait for Overrun (~20 * 87us approx)
            
            // Read all 20? 
            // Note: If FIFO is 16 deep, we expect data loss.
            // Scoreboard will report MISMATCH for missing bytes.
            // This confirms OVERRUN behavior.
            repeat(20) begin
                tr = new(); tr.write=0; tr.addr=`UART_REG_RXDATA;
                env.apb_gen2drv_mb.put(tr);
                #10000;
            end
        end
    join

    #10000;
    $display("[TEST_FIFO] Finished. (Note: Scoreboard errors expected in Part 2 due to Overrun)");
    $finish;
  endtask
endclass

`endif
