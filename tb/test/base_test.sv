`ifndef BASE_TEST_SV
`define BASE_TEST_SV

`include "environment.sv"

class base_test;
    string      name;
    environment env;

    function new(string name = "base_test");
        this.name = name;
        env = new("env");
    endfunction

  // Hook to be called from tb_top after env.build()
  virtual task configure(); endtask

    virtual task run();
        $display("[%s] Starting test", name);
        env.run();
        // Default: wait some time
        #10000;
        $display("[%s] Finished test", name);
    endtask
endclass

`endif

