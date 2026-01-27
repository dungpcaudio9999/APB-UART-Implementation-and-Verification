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
    virtual apb_if.TB_DRV  apb_vif_drv;
    virtual apb_if.TB_MON  apb_vif_mon;
    virtual uart_if.TB_DRV uart_vif_drv;
    virtual uart_if.TB_MON uart_vif_mon;

    mailbox #(apb_transaction)  apb_gen2drv_mb, apb_mon_mb, apb_mon_cov_mb; // Added COV MB
    mailbox #(uart_transaction) uart_gen2drv_mb, uart_mon_mb, uart_mon_cov_mb; // Added UART COV MB

    apb_generator apb_gen; apb_driver apb_drv; apb_monitor apb_mon;
    uart_driver uart_drv; uart_monitor uart_mon; uart_config uart_cfg;
    scoreboard sb; coverage_collector cov;

    function new(string name="env");
        apb_gen2drv_mb = new(); apb_mon_mb = new(); apb_mon_cov_mb = new();
        uart_gen2drv_mb = new(); uart_mon_mb = new(); uart_mon_cov_mb = new();
    endfunction

    function void build();
        apb_gen = new("apb_gen", apb_gen2drv_mb);
        apb_drv = new("apb_drv", apb_vif_drv, apb_gen2drv_mb);
        // Pass 2 mailboxes to monitor
        apb_mon = new("apb_mon", apb_vif_mon, apb_mon_mb, apb_mon_cov_mb);

        uart_cfg = new();
        uart_drv = new("uart_drv", uart_vif_drv, uart_cfg, uart_gen2drv_mb);
        // Pass 2 mailboxes to monitor (add coverage MB)
        uart_mon = new("uart_mon", uart_vif_mon, uart_cfg, uart_mon_mb, uart_mon_cov_mb);

        sb  = new("sb", apb_mon_mb, uart_mon_mb);
        cov = new("cov", apb_mon_cov_mb, uart_mon_cov_mb, uart_cfg); // Pass both MBs and CFG
    endfunction

    task run();
        fork
            apb_gen.run(); apb_drv.run(); apb_mon.run();
            uart_drv.run(); uart_mon.run();
            sb.run(); cov.run();
        join_none
    endtask
endclass
`endif