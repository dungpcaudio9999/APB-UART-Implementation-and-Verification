`ifndef TEST_SANITY_SV
`define TEST_SANITY_SV
`include "base_test.sv"

class test_sanity extends base_test;
  function new(string name="test_sanity"); super.new(name); endfunction
  
  virtual task run();
    apb_transaction tr;
    env.apb_gen.num_transactions = 0; // Disable auto random
    super.run(); // Start Env
    
    // Config 8N1
    tr=new; tr.write=1; tr.addr=`UART_REG_CONFIG; tr.wdata=3;
    env.apb_gen2drv_mb.put(tr);
    
    // Send Data
    repeat(5) begin
       tr=new; tr.write=1; tr.addr=`UART_REG_TXDATA; tr.wdata=$random;
       env.apb_gen2drv_mb.put(tr);
       
       tr=new; tr.write=1; tr.addr=`UART_REG_CONTROL; tr.wdata=1;
       env.apb_gen2drv_mb.put(tr);
       
       // Wait for > 1 baud clock cycle (approx 8.68us) to ensure FSM catches it on clk_tx pulse
       #20000; 

       // Clear Start Bit (Pulse)
       tr=new; tr.write=1; tr.addr=`UART_REG_CONTROL; tr.wdata=0;
       env.apb_gen2drv_mb.put(tr);

       #200000;
    end
    #10000; $finish;
  endtask
endclass
`endif