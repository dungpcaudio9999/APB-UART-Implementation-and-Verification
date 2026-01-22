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
    endtask
endclass

`endif

