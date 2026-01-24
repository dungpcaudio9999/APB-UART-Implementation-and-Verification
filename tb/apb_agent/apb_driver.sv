`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

`include "apb_if.sv"
`include "transaction.sv"

class apb_driver;
  string                      name;
  virtual apb_if.TB_DRV       vif;
  mailbox #(apb_transaction)  in_mb;

  function new(string name = "apb_driver",
               virtual apb_if.TB_DRV vif,
               mailbox #(apb_transaction) in_mb);
    this.name  = name;
    this.vif   = vif;
    this.in_mb = in_mb;
  endfunction

  task reset_signals();
    vif.cb_drv.psel    <= 1'b0;
    vif.cb_drv.penable <= 1'b0;
    vif.cb_drv.pwrite  <= 1'b0;
    vif.cb_drv.pstrb   <= 4'hF;
    vif.cb_drv.paddr   <= '0;
    vif.cb_drv.pwdata  <= '0;
  endtask

  task drive(apb_transaction tr);
    // Simple APB2 access
    @(vif.cb_drv);
    vif.cb_drv.psel   <= 1'b1;
    vif.cb_drv.pwrite <= tr.write;
    vif.cb_drv.pstrb  <= tr.strb;
    vif.cb_drv.paddr  <= tr.addr;
    vif.cb_drv.pwdata <= tr.wdata;

    @(vif.cb_drv);
    vif.cb_drv.penable <= 1'b1;

    // Wait for ready
    do @(vif.cb_drv); while (!vif.cb_drv.pready);

    if (!tr.write)
      tr.rdata = vif.cb_drv.prdata;

    // Deassert
    vif.cb_drv.psel    <= 1'b0;
    vif.cb_drv.penable <= 1'b0;
  endtask

  task run();
    apb_transaction tr;
    reset_signals();
    forever begin
      in_mb.get(tr);
      drive(tr);
    end
  endtask
endclass

`endif

