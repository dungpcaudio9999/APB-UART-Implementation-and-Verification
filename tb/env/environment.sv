`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "apb_if.sv"
`include "uart_if.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "apb_generator.sv"
`include "uart_driver.sv"
`include "uart_monitor.sv"
`include "scoreboard.sv"
`include "coverage.sv"

class environment;
  string name;

  // Virtual interfaces
  virtual apb_if.TB_DRV  apb_vif_drv;
  virtual apb_if.TB_MON  apb_vif_mon;
  virtual uart_if.TB_DRV uart_vif_drv;
  virtual uart_if.TB_MON uart_vif_mon;

  // Mailboxes
  mailbox #(apb_transaction)  apb_gen2drv_mb;
  mailbox #(apb_transaction)  apb_mon_mb;
  mailbox #(uart_transaction) uart_gen2drv_mb;
  mailbox #(uart_transaction) uart_mon_mb;

  // Components
  apb_generator      apb_gen;
  apb_driver         apb_drv;
  apb_monitor        apb_mon;
  uart_driver        uart_drv;
  uart_monitor       uart_mon;
  scoreboard         sb;
  coverage_collector cov;

  // Clock reference for coverage
  logic pclk_ref;

  function new(string name = "environment");
    this.name = name;
    apb_gen2drv_mb  = new();
    apb_mon_mb      = new();
    uart_gen2drv_mb = new();
    uart_mon_mb     = new();
  endfunction

  function void build(virtual apb_if.TB_DRV  apb_vif_drv,
                      virtual apb_if.TB_MON  apb_vif_mon,
                      virtual uart_if.TB_DRV uart_vif_drv,
                      virtual uart_if.TB_MON uart_vif_mon,
                      ref logic pclk_ref);
    this.apb_vif_drv  = apb_vif_drv;
    this.apb_vif_mon  = apb_vif_mon;
    this.uart_vif_drv = uart_vif_drv;
    this.uart_vif_mon = uart_vif_mon;
    this.pclk_ref     = pclk_ref;

    apb_gen = new("apb_gen", apb_gen2drv_mb);
    apb_drv = new("apb_drv", apb_vif_drv, apb_gen2drv_mb);
    apb_mon = new("apb_mon", apb_vif_mon, apb_mon_mb);

    uart_drv = new("uart_drv", uart_vif_drv, uart_gen2drv_mb);
    uart_mon = new("uart_mon", uart_vif_mon, uart_mon_mb);

    sb  = new("scoreboard", apb_mon_mb, uart_mon_mb);
    cov = new("coverage", apb_mon_mb, pclk_ref);
  endfunction

  task run();
    fork
      apb_gen.run();
      apb_drv.run();
      apb_mon.run();
      uart_drv.run();
      uart_mon.run();
      sb.run();
      cov.run();
    join_none
  endtask

endclass

`endif

