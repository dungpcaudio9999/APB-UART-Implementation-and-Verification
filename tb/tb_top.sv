`timescale 1ns/1ps

`include "apb_if.sv"
`include "uart_if.sv"
`include "transaction.sv"
`include "environment.sv"
//// Tests
`include "base_test.sv"
`include "test_sanity.sv"
`include "test_tx.sv"
`include "test_rx.sv"
`include "test_flow_control.sv"
`include "test_error_injection.sv"
`include "test_config_modes.sv"
`include "test_reset_stress.sv"
`include "test_full_regression.sv"
`include "test_fifo.sv"

module tb_top;

    // Clocks & reset
    logic clk;
    logic reset_n;
    logic pclk;
    logic preset_n;
    logic uart_clk;

    initial begin
        pclk = 1'b0;
        forever #10 pclk = ~pclk;
    end

    initial begin
        uart_clk = 1'b0;
        forever #10 uart_clk = ~uart_clk;
    end

    initial begin
        // Active-low resets for both UART core and APB side
        reset_n  = 1'b0;
        preset_n = 1'b0;
        #20;
        reset_n  = 1'b1;
        preset_n = 1'b1;
    end

    // For this skeleton, use uart_clk as the UART core clock
    assign clk = uart_clk;

    // Interfaces
    apb_if  apb_if_i (pclk, preset_n);
    uart_if uart_if_i (uart_clk);

    // Default strobes/flow-control
    initial begin
        apb_if_i.pstrb = 4'hF;
        uart_if_i.cts_n = 1'b0; // allow transmit by default (active-low)
        uart_if_i.rx    = 1'b1; // idle high
        uart_if_i.rx    = 1'b1; // idle high
    end

    // Monitor for debug
    initial begin
        $monitor("[%0t] [TB_TOP] UART TX Toggled: %b", $time, uart_if_i.tx);
    end

    // DUT (Đảm bảo tên module uart khớp với file RTL của Đại ca)
    uart dut (
        .clk     (clk),
        .reset_n (reset_n),
        .pclk    (pclk),
        .preset_n(preset_n),
        .psel    (apb_if_i.psel),
        .penable (apb_if_i.penable),
        .pwrite  (apb_if_i.pwrite),
        .pstrb   (apb_if_i.pstrb),
        .paddr   (apb_if_i.paddr),
        .pwdata  (apb_if_i.pwdata),
        .rx      (uart_if_i.rx),
        .cts_n   (uart_if_i.cts_n),
        .pready  (apb_if_i.pready),
        .pslverr (apb_if_i.pslverr),
        .prdata  (apb_if_i.prdata),
        .tx      (uart_if_i.tx),
        .rts_n   (uart_if_i.rts_n)
    );

    // Test and Environment
    environment env;
    base_test   test;

    string test_name;

    initial begin
        env = new("env");
    
        // Gán trực tiếp Interface, bỏ qua Modport để tránh lỗi type cast
        // Và bỏ dòng gán pclk_ref vì Env mới không dùng nữa.
        env.apb_vif_drv   = apb_if_i;
        env.apb_vif_mon   = apb_if_i;
        env.uart_vif_drv  = uart_if_i;
        env.uart_vif_mon  = uart_if_i;
        
        env.build();
        // ---------------------------------------------

        if (!$value$plusargs("TESTNAME=%s", test_name)) begin
            test_name = "test_sanity";
            $display("No +TESTNAME provided. Running default: %s", test_name);
        end else begin
            $display("Running test: %s", test_name);
        end

        case (test_name)
            "test_sanity": begin
                test_sanity t;
                t = new();
                test = t;
            end
            "test_tx": begin
                test_tx t;
                t = new();
                test = t;
            end
            "test_rx": begin
                test_rx t;
                t = new();
                test = t;
            end
            "test_flow_control": begin
                test_flow_control t;
                t = new();
                test = t;
            end
            "test_error_injection": begin
                test_error_injection t;
                t = new();
                test = t;
            end
            "test_config_modes": begin
                test_config_modes t;
                t = new();
                test = t;
            end
            "test_full_regression": begin
                test_full_regression t;
                t = new();
                test = t;
            end
            "test_reset_stress": begin
                test_reset_stress t;
                t = new();
                test = t;
            end
            "test_fifo": begin
                test_fifo t;
                t = new();
                test = t;
            end
            default: begin
                $fatal("Test name '%s' not found.", test_name);
            end
        endcase

        test.env = env;
        test.configure();
        test.run();

        $finish;
    end

endmodule