`ifndef TEST_FULL_REGRESSION_SV
`define TEST_FULL_REGRESSION_SV

`include "base_test.sv"

class test_full_regression extends base_test;
  function new();
    super.new("test_full_regression");
  endfunction

  virtual task configure();
    // Disable automatic initial generation
    env.apb_gen.num_transactions = 0;
  endtask

  virtual task run();
    $display("[%s] Starting Full Regression Suite...", name);
    env.run();
    
    // ======================================================
    // 0. DUT CONFIGURATION
    // ======================================================
    $display("[REGRESSION] >>> Configuring DUT (8 Data Bits) <<<");
    // Write 0x03 to Config Register (Addr 0x08) -> 8 Data Bits, No Parity, 1 Stop
    // We use a temporary transaction for this setup
    begin
        apb_transaction cfg_tr = new();
        void'(cfg_tr.randomize() with {
            write == 1;
            addr == `UART_REG_CONFIG;
            wdata == 32'h3;
        });
        env.apb_gen.out_mb.put(cfg_tr);
    end
    #2000; // Wait for config to settle
    
    // ======================================================
    // 1. SANITY TEST
    // ======================================================
    $display("\n[REGRESSION] >>> Running TEST_SANITY <<<");
    // Enable all randomness
    env.apb_gen.blueprint.rand_mode(1); 
    env.apb_gen.blueprint.c_default.constraint_mode(1);
    
    env.apb_gen.generate_batch(10);
    #2000;

    // ======================================================
    // 2. TX TEST (Write to TXDATA)
    // ======================================================
    $display("\n[REGRESSION] >>> Running TEST_TX <<<");
    // Constrain to Writes on TXDATA
    assert(env.apb_gen.blueprint.randomize() with {
      write == 1;
      addr == `UART_REG_TXDATA;
    });
    // Lock these choices so next randomizes don't change them
    env.apb_gen.blueprint.write.rand_mode(0);
    env.apb_gen.blueprint.addr.rand_mode(0);
    
    env.apb_gen.generate_batch(50);
    #5000;

    // ======================================================
    // 3. RX TEST (Read from RXDATA)
    // ======================================================
    $display("\n[REGRESSION] >>> Running TEST_RX <<<");
    // Release locks first
    env.apb_gen.blueprint.write.rand_mode(1);
    env.apb_gen.blueprint.addr.rand_mode(1);
    
    // Constrain to Reads on RXDATA
    assert(env.apb_gen.blueprint.randomize() with {
      write == 0;
      addr == `UART_REG_RXDATA;
    });
    env.apb_gen.blueprint.write.rand_mode(0);
    env.apb_gen.blueprint.addr.rand_mode(0);
    
    // FORK: Send UART Data (Driver) while Reading APB (Monitor)
    fork
      // Thread 1: UART Generator (Inject data into DUT)
      begin
         uart_transaction rx_tr;
         $display("[REGRESSION] Sending 50 UART bytes to DUT (Total ~9ms)...");
         for(int i=0; i<50; i++) begin
            rx_tr = new();
            void'(rx_tr.randomize());
            rx_tr.stop_bits = 1; 
            rx_tr.delay = 10;    // 10 bit periods delay (~86us)
            env.uart_gen2drv_mb.put(rx_tr);
         end
      end

      // Thread 2: APB Generator (Read data from DUT)
      // Throttle APB reads to match UART speed (approx 1 byte every ~200us)
      begin
          // Wait for first byte to definitely arrive (10 bits data + 10 bits delay = ~174us)
          for(int i=0; i<50; i++) begin
              #200000; // Wait 200us
              env.apb_gen.generate_batch(1);
          end
      end
    join
    
    // Drain time
    #200000;

    // ======================================================
    // 4. FIFO TEST (Flood)
    // ======================================================
    $display("\n[REGRESSION] >>> Running TEST_FIFO <<<");
    // Release locks
    env.apb_gen.blueprint.write.rand_mode(1);
    env.apb_gen.blueprint.addr.rand_mode(1);
    
    assert(env.apb_gen.blueprint.randomize() with {
      write == 1;
      addr == `UART_REG_TXDATA;
    });
    env.apb_gen.blueprint.write.rand_mode(0);
    env.apb_gen.blueprint.addr.rand_mode(0);
    
    // Send 30 items (assuming FIFO < 30)
    env.apb_gen.generate_batch(30);
    #5000;

    $display("\n[REGRESSION] All tests completed.");
    $finish;
  endtask
endclass

`endif
