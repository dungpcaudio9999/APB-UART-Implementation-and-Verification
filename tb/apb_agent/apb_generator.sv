`ifndef APB_GENERATOR_SV
`define APB_GENERATOR_SV

`include "transaction.sv"

class apb_generator;
  string                     name;
  mailbox #(apb_transaction) out_mb;
  apb_transaction            blueprint;
  int                        num_transactions;

  function new(string name = "apb_generator",
               mailbox #(apb_transaction) out_mb,
               int num_transactions = 100);
    this.name             = name;
    this.out_mb           = out_mb;
    this.num_transactions = num_transactions;
    this.blueprint        = new("blueprint");
  endfunction

  virtual task run();
    apb_transaction tr;
    for (int i = 0; i < num_transactions; i++) begin
      // Randomize the blueprint (which may have constraints from the Test)
      assert(blueprint.randomize());
      // Create a copy to send to mailbox
      tr = new blueprint; 
      out_mb.put(tr);
    end
  endtask
endclass

`endif

