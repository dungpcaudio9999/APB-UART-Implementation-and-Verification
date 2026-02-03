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
            //$display("[%s] Received APB TR: Addr=%h, Data=0x%02h, Write=%b", name, tr.addr, (tr.write ? tr.wdata[7:0] : tr.rdata[7:0]), tr.write);
            if (tr.write && tr.addr == `UART_REG_TXDATA) begin
                // CPU sends data to UART => Expect TX output
                tx_queue.push_back(tr.wdata[7:0]);
                $display("[FLOW_SCB] APB Write TX Data: 0x%02h. Queue size: %0d", tr.wdata[7:0], tx_queue.size());
            end
            else if (!tr.write && tr.addr == `UART_REG_RXDATA) begin
                // CPU reads data from UART => Compare with what was received
                if (rx_queue.size() > 0) begin
                    bit [7:0] expected = rx_queue.pop_front();
                    if (tr.rdata[7:0] == expected)
                        $display("[FLOW_SCB] READ MATCH!  Addr: %0h | Expected: 0x%02h | Actual: 0x%02h", tr.addr, expected, tr.rdata[7:0]);
                    else
                        $error("[FLOW_SCB] READ MISMATCH! Addr: %0h | Expected: 0x%02h | Actual: 0x%02h", tr.addr, expected, tr.rdata[7:0]);
                end else begin
                    $warning("[FLOW_SCB] APB Read RX Empty Queue! Addr: %0h Data: 0x%02h", tr.addr, tr.rdata);
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
            
            if (tr.dir == uart_transaction::TX) begin
                // Data from DUT (Outcome of APB Write)
                if (tx_queue.size() > 0) begin
                     bit [7:0] expected = tx_queue.pop_front();
                     if (tr.data == expected)
                         $display("[FLOW_SCB] TX MATCH! Data: 0x%02h", tr.data);
                     else
                         $error("[FLOW_SCB] TX MISMATCH! Expected: 0x%02h | Actual: 0x%02h", expected, tr.data);
                end else begin
                     $warning("[FLOW_SCB] Unexpected TX Data from DUT: 0x%02h (Queue Empty)", tr.data);
                end
            end 
            else begin // tr.dir == uart_transaction::RX
                 // Data to DUT (Input for APB Read)
                 rx_queue.push_back(tr.data);
                 $display("[FLOW_SCB] UART RX (Agent->DUT): 0x%02h. Pushed to RX Queue. Size: %0d", tr.data, rx_queue.size());
            end
        end
    endtask

endclass

`endif

