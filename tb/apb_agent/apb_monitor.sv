`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

`include "apb_if.sv"
`include "transaction.sv"

class apb_monitor;
  string                      name;
  virtual apb_if.TB_MON       vif;
  mailbox #(apb_transaction)  out_mb;

  function new(string name = "apb_monitor",
               virtual apb_if.TB_MON vif,
               mailbox #(apb_transaction) out_mb);
    this.name   = name;
    this.vif    = vif;
    this.out_mb = out_mb;
  endfunction

  task run();
    apb_transaction tr;
    forever begin
      @(posedge vif.cb_mon.psel);
      tr = new("apb_mon_tr");
      tr.write = vif.cb_mon.pwrite;
      tr.addr  = vif.cb_mon.paddr;
      tr.wdata = vif.cb_mon.pwdata;

      // wait for completion
      do @(vif.cb_mon); while (!vif.cb_mon.pready);

      if (!tr.write)
        tr.rdata = vif.cb_mon.prdata;

      out_mb.put(tr);
    end
  endtask
endclass

`endif

