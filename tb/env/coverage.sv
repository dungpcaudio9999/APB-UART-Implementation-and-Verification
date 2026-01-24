`ifndef COVERAGE_SV
`define COVERAGE_SV

`include "transaction.sv"
`include "apb_defines.sv"

// Note: this is a simple placeholder; you may want to integrate this more tightly with your clocking strategy.
class coverage_collector;
  string name;

  // Handles to monitored transactions
  mailbox #(apb_transaction) apb_mon_mb;

  // Internal sampled variables
  bit [`APB_ADDR_WIDTH-1:0] addr;
  logic                     clk;

  covergroup cg_apb_addr @(posedge clk);
    option.per_instance = 1;
    addr_cp : coverpoint addr {
      bins tx_reg   = {`UART_REG_TXDATA};
      bins rx_reg   = {`UART_REG_RXDATA};
      bins status   = {`UART_REG_STATUS};
      bins control  = {`UART_REG_CONTROL};
    }
  endgroup

  function new(string name = "coverage_collector",
               mailbox #(apb_transaction) apb_mon_mb,
               ref logic clk);
    this.name       = name;
    this.apb_mon_mb = apb_mon_mb;
    this.clk        = clk;
    cg_apb_addr     = new();
  endfunction

  task run();
    apb_transaction tr;
    forever begin
      apb_mon_mb.get(tr);
      addr = tr.addr;
      // covergroup samples on posedge clk
    end
  endtask
endclass

`endif

