`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

`include "uart_if.sv"
`include "transaction.sv"

class uart_monitor;
  string                          name;
  virtual uart_if.TB_MON          vif;
  mailbox #(uart_transaction)     out_mb;

  function new(string name = "uart_monitor",
               virtual uart_if.TB_MON vif,
               mailbox #(uart_transaction) out_mb);
    this.name   = name;
    this.vif    = vif;
    this.out_mb = out_mb;
  endfunction

  // TODO: Decode serial tx line into bytes
  task run();
    forever begin
      // Placeholder: wait on clock, user to implement decode logic
      @(vif.cb_mon);
    end
  endtask
endclass

`endif

