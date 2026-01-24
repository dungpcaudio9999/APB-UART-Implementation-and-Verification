`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`include "transaction.sv"
`include "apb_defines.sv"
`include "uart_if.sv"
`include "apb_if.sv"

class scoreboard;
    string name;

    // Channels
    mailbox #(apb_transaction)  apb_mon_mb;
    mailbox #(uart_transaction) uart_mon_mb;

    // Queues for storage
    bit [7:0] tx_queue[$];
    bit [7:0] rx_queue[$];

    function new(string name = "scoreboard",
               mailbox #(apb_transaction) apb_mon_mb,
               mailbox #(uart_transaction) uart_mon_mb);
        this.name        = name;
        this.apb_mon_mb  = apb_mon_mb;
        this.uart_mon_mb = uart_mon_mb;
    endfunction

    task run();
        $display("[%s] Scoreboard started...", name);
        fork
            process_apb();
            process_uart();
        join_none
    endtask

    // Handle APB Transactions (CPU side)
    task process_apb();
        apb_transaction tr;
        forever begin
            apb_mon_mb.get(tr);
            if (tr.write && tr.addr == `UART_REG_TXDATA) begin
                // CPU sends data to UART => Expect TX output
                tx_queue.push_back(tr.wdata[7:0]);
                $display("[%s] APB Write TX Data: 0x%02h. Queue size: %0d", name, tr.wdata[7:0], tx_queue.size());
            end
            else if (!tr.write && tr.addr == `UART_REG_RXDATA) begin
                // CPU reads data from UART => Compare with what was received
                if (rx_queue.size() > 0) begin
                    bit [7:0] expected = rx_queue.pop_front();
                    if (tr.rdata[7:0] == expected)
                        $display("[%s] READ MATCH!  Addr: %0h | Expected: 0x%02h | Actual: 0x%02h", name, tr.addr, expected, tr.rdata[7:0]);
                    else
                        $error("[%s] READ MISMATCH! Addr: %0h | Expected: 0x%02h | Actual: 0x%02h", name, tr.addr, expected, tr.rdata[7:0]);
                end else begin
                    $warning("[%s] APB Read RX Empty Queue! Addr: %0h Data: 0x%02h", name, tr.addr, tr.rdata);
                end
            end
        end
    endtask

    // Handle UART Transactions (Serial side)
    task process_uart();
        uart_transaction tr;
        forever begin
            uart_mon_mb.get(tr);
            // In typical UART VIP:
            // - If data comes IN (rx pin driven), it's RX for DUT.
            // - If data goes OUT (tx pin sensed), it's TX from DUT.
            // The monitor needs to discern direction or we infer from context.
            // Assuming uart_monitor sends ALL seen bytes.
            
            // Let's assume the monitor tags logic or we just check TX queue for default
            // For now, let's implement the Check TX part first:
            // If we have data in tx_queue, check it against this.
            
            if (tx_queue.size() > 0) begin
                 bit [7:0] expected = tx_queue.pop_front();
                 if (tr.data == expected)
                     $display("[%s] TX MATCH! Data: 0x%02h", name, tr.data);
                 else
                     $error("[%s] TX MISMATCH! Expected: 0x%02h | Actual: 0x%02h", name, expected, tr.data);
            end else begin
                 // If queue empty, maybe it is RX data that the UART Agent SENT to DUT?
                 // For simplified scoreboard, let's assume valid TX check first.
                 // We push to rx_queue to verify APB Read later.
                 rx_queue.push_back(tr.data);
                 $display("[%s] UART RX (Agent->DUT): 0x%02h. Pushed to RX Queue.", name, tr.data);
            end
        end
    endtask

endclass

`endif

