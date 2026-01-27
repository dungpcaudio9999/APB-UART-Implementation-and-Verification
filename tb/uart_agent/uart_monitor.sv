`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV
`include "uart_if.sv"
`include "transaction.sv"

class uart_monitor;
    string name;
    virtual uart_if.TB_MON vif;
    uart_config cfg;
    mailbox #(uart_transaction) out_mb;
    mailbox #(uart_transaction) cov_mb; // Added coverage MB
    real bit_period;

    function new(string name, virtual uart_if.TB_MON vif, uart_config cfg, mailbox #(uart_transaction) out_mb, mailbox #(uart_transaction) cov_mb);
        this.name=name; this.vif=vif; this.cfg=cfg; this.out_mb=out_mb; this.cov_mb=cov_mb;
        this.bit_period = (1000000000.0 / cfg.baud_rate);
    endfunction

    task run();
        fork 
            monitor_tx();
            monitor_rx(); 
        join_none
    endtask

    task monitor_tx();
        uart_transaction tr;
        forever begin
            // 1. Wait for Start Bit (Falling Edge on RAW signal)
            @(negedge vif.tx);

            tr = new("mon_tx"); 
            tr.dir = uart_transaction::TX;

            // 2. Verify it's a real start bit (check middle)
            #(bit_period/2); 
            if(vif.tx == 0) begin
                #(bit_period); // Move to middle of D0

                // 3. Sample Data
                for(int i=0; i<cfg.data_width; i++) begin
                    tr.data[i] = vif.tx; 
                    #(bit_period);
                end

                // 4. Skip Parity if enabled
                if(cfg.parity_en) #(bit_period);

                // 5. Check Stop Bit
                if (vif.tx == 1) begin
                    $display("[FLOW_MON] UART Captured TX: %h", tr.data);
                    out_mb.put(tr);
                    
                    // Send copy to coverage
                    begin
                        uart_transaction tr_cov = new tr;
                        cov_mb.put(tr_cov);
                    end
                end else begin
                    $warning("[%s] Framing Error on TX! Expected Stop Bit=1, got %b. Data: %h", name, vif.tx, tr.data);
                    out_mb.put(tr); 
                end

                // 6. Wait for line to go High (Idle) + Margin
                // Wait until it is high
                wait(vif.tx == 1);
                // Add small margin to avoid sampling glitch at the edge of stop bit
                #(bit_period/2);
            end
        end
    endtask

    task monitor_rx();
        uart_transaction tr;
        forever begin
            // 1. Wait for Start Bit (Falling Edge on RAW signal)
            @(negedge vif.rx);

            tr = new("mon_rx"); 
            tr.dir = uart_transaction::RX;

            // 2. Verify it's a real start bit (check middle)
            #(bit_period/2); 
            if(vif.rx == 0) begin
                #(bit_period); // Move to middle of D0

                // 3. Sample Data
                for(int i=0; i<cfg.data_width; i++) begin
                    tr.data[i] = vif.rx; 
                    #(bit_period);
                end

                // 4. Skip Parity if enabled
                if(cfg.parity_en) #(bit_period);

                // 5. Capture
                // For RX, we assume we want to see what was driven to DUT
                if (vif.rx == 1) begin
                    $display("[FLOW_MON] UART Captured RX: %h", tr.data);
                    out_mb.put(tr);

                    // Send copy to coverage
                    begin
                        uart_transaction tr_cov = new tr;
                        cov_mb.put(tr_cov);
                    end
                end else begin
                    $warning("[%s] Framing Error on RX! Expected Stop Bit=1, got %b. Data: %h", name, vif.rx, tr.data);
                    out_mb.put(tr);
                end

                // 6. Wait for line to go High (Idle)
                wait(vif.rx == 1);
                #(bit_period/2);
            end
        end
    endtask
endclass
`endif