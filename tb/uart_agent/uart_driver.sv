`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

`include "uart_if.sv"
`include "transaction.sv"

class uart_driver;
    string                        name;
    virtual uart_if.TB_DRV        vif;
    mailbox #(uart_transaction)   in_mb;

    function new(string name = "uart_driver",
               virtual uart_if.TB_DRV vif,
               mailbox #(uart_transaction) in_mb);
        this.name  = name;
        this.vif   = vif;
        this.in_mb = in_mb;
    endfunction

    // TODO: Implement UART bit-level driving according to baud rate
    task send_byte(uart_transaction tr);
        // Placeholder: user to implement serial protocol
        @(vif.cb_tx);
        // Real implementation: serialize start bit, data bits, parity, stop bits to rx
    endtask

    task run();
        uart_transaction tr;
        forever begin
            in_mb.get(tr);
            send_byte(tr);
        end
    endtask
endclass

`endif

