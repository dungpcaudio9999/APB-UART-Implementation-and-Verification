`ifndef BASE_TEST_SV
`define BASE_TEST_SV
`include "environment.sv"

class base_test;
  string name;
  environment env; // Assigned from tb_top

  function new(string name="base_test"); this.name=name; endfunction
  virtual task configure(); endtask
  virtual task run();
    $display("Starting %s", name);
    env.run();
    #2000000; // Timeout
    $display("Finished %s", name);
  endtask
endclass
`endif