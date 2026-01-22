`ifndef UART_IF_SV
`define UART_IF_SV

interface uart_if(input logic clk);

    logic rx;
    logic tx;
    logic cts_n;
    logic rts_n;

    // For TB, usually drive rx and monitor tx
    clocking cb_tx @(posedge clk);
    default input #1step output #1step;
        output rx, cts_n;
        input  tx, rts_n;
    endclocking

    clocking cb_mon @(posedge clk);
    default input #1step output #1step;
        input rx, tx, cts_n, rts_n;
    endclocking

    modport TB_DRV (clocking cb_tx);
    modport TB_MON (clocking cb_mon);
    modport DUT (input rx, cts_n, output tx, rts_n);

endinterface

`endif

