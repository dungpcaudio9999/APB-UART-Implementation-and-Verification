`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`include "transaction.sv"
`include "apb_defines.sv"

class scoreboard;
string name;

// Channels
mailbox #(apb_transaction)  apb_mon_mb;
mailbox #(uart_transaction) uart_mon_mb;

function new(string name = "scoreboard",
           mailbox #(apb_transaction) apb_mon_mb,
           mailbox #(uart_transaction) uart_mon_mb);
    this.name        = name;
    this.apb_mon_mb  = apb_mon_mb;
    this.uart_mon_mb = uart_mon_mb;
endfunction


task run();
endtask

task checker();
endtask
endclass

`endif

