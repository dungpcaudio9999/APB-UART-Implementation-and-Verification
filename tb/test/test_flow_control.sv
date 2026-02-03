`ifndef TEST_FLOW_CONTROL_SV
`define TEST_FLOW_CONTROL_SV

`include "base_test.sv"

class test_flow_control extends base_test;
  function new();
    super.new("test_flow_control");
  endfunction

  virtual task configure();
    env.uart_cfg.data_width = 8;
    env.uart_cfg.stop_bits  = 1;
    env.uart_cfg.parity_en  = 0;

    // We will verify RX Flow Control (RTS)
    // Scenario: Flood RX FIFO faster than APB reads it.
    // RTS should assert to pause UART Driver. 
    // If successful, all data matches. If failed, overflow/mismatch.
    
    env.apb_gen.blueprint.trans_kind = apb_transaction::RX_READ;
    env.apb_gen.blueprint.trans_kind.rand_mode(0);
    env.apb_gen.num_transactions = 0; 
  endtask
  
  virtual task run();
    apb_transaction cfg_tr, ctrl_tr;
    
    env.run();

    // 1. Config DUT
    $display("[TEST_FC] Configuring DUT...");
    cfg_tr = new(); cfg_tr.write=1; cfg_tr.addr=`UART_REG_CONFIG; cfg_tr.wdata=3;
    env.apb_gen2drv_mb.put(cfg_tr);
    #1000;
    
    // 2. Enable (assuming RX relies on global enable or default)
    // Note: We removed explicit 'Start TX' write to avoid spurious TX logs, 
    // unless RX also needs it. Assuming RX works as per test_rx.
    
    // 3. Stress Test: Send 32 bytes (Assume FIFO=16)
    $display("[TEST_FC] Starting RX Stress Test (32 bytes)...");
    
    fork
        // Thread A: UART Sender (Fast)
        begin
            repeat(32) begin
                uart_transaction uart_tr = new();
                if (!uart_tr.randomize() with {
                    stop_bits == 1;
                    delay inside {[1:2]}; // Very Fast (Back-to-back)
                    dir == uart_transaction::RX;
                }) $fatal("Randomize failed");
                env.uart_gen2drv_mb.put(uart_tr);
                // No wait here, let driver push as fast as possible
            end
        end
        
        // Thread B: APB Reader (Slow / Delayed)
        begin
            #500000; // Wait until FIFO likely full
            repeat(32) begin
                env.apb_gen.generate_batch(1); // Read 1
                #100000; // Reading slowly
            end
        end
    join
    
    #100000;
    
    // ---------------------------------------------------------
    // 4. CTS Flow Control Verification (TX Side - Stress)
    // ---------------------------------------------------------
    $display("[TEST_FC] Starting CTS Verification (TX Pause with Full FIFO)...");
    
    // 4a. Assert CTS (Stop Transmission)
    env.uart_vif_drv.cb_drv.cts_n <= 1'b1; 
    #1000;

    // 4b. Fill TX FIFO (16 bytes)
    // Use blueprint to generate TX_WRITEs
    env.apb_gen.blueprint.trans_kind = apb_transaction::TX_WRITE;
    env.apb_gen.blueprint.trans_kind.rand_mode(0);
    // Reuse constraint from test_tx logic implicitly or let it random valid data
    // Just create a small loop to push valid data
    repeat(16) begin
        cfg_tr = new(); 
        cfg_tr.write=1; cfg_tr.addr=`UART_REG_TXDATA; cfg_tr.wdata=$random;
        env.apb_gen2drv_mb.put(cfg_tr);
    end
    #1000; // Wait for APB writes
    
    // 4c. Trigger Start
    ctrl_tr = new(); ctrl_tr.write=1; ctrl_tr.addr=`UART_REG_CONTROL; ctrl_tr.wdata=1; 
    env.apb_gen2drv_mb.put(ctrl_tr);
    
    // 4d. Verify Pause: Wait significant time (e.g. time for 5 bytes ~430us)
    // If CTS works, TX should NOT toggle at all.
    repeat(5) #87000; // ~435us
    
    if (env.uart_vif_mon.tx == 0) begin
        $error("[TEST_FC] CTS FAILURE! TX Toggled/Transmitting despite CTS=1");
    end else begin
        $display("[TEST_FC] CTS Check: OK. TX held high for %0t ns", $time);
    end
    
    // 4e. Release CTS (Flush Buffer)
    $display("[TEST_FC] Releasing CTS. Expecting 16 bytes...");
    env.uart_vif_drv.cb_drv.cts_n <= 1'b0;
    
    // 4f. Wait for drain (16 * 87us = ~1.4ms)
    #2000000; 
    
    $display("[TEST_FC] Finished.");
    $finish;
  endtask
endclass

`endif
