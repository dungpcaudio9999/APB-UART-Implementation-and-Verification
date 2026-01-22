`ifndef TRANSACTION_SV
`define TRANSACTION_SV

`include "apb_defines.sv"

// ---------------------------------------------------------
// 1. APB TRANSACTION
// ---------------------------------------------------------
class apb_transaction;
    rand bit                        write;
    rand bit [`APB_ADDR_WIDTH-1:0]  addr;
    rand bit [3:0]                  strb;
    rand bit [`APB_DATA_WIDTH-1:0]  wdata;
    bit [`APB_DATA_WIDTH-1:0]  rdata;

    string name;

    // Constraint địa chỉ hợp lệ
    constraint c_default {
    addr inside { `UART_REG_TXDATA,
                  `UART_REG_RXDATA,
                  `UART_REG_CONFIG, 
                  `UART_REG_STATUS,
                  `UART_REG_CONTROL };
    }

    // Constraint địa chỉ phải chia hết cho 4 (Aligned)
    constraint c_align {
        addr[1:0] == 2'b00;
    }

    function new(string name = "apb_tr");
        this.name = name;
        this.strb = 4'hF;
    endfunction
endclass


// ---------------------------------------------------------
// 2. UART TRANSACTION
// ---------------------------------------------------------
class uart_transaction;
    rand bit [7:0] data;
    rand bit       parity_en;
    rand bit       parity_even;
    rand int       stop_bits; // 1 or 2
    rand int       delay;     // Delay giữa các gói tin

    string name;

    // <--- QUAN TRỌNG: Phải giới hạn stop_bits
    constraint c_stop {
        stop_bits inside {1, 2};
    }

    // Ràng buộc delay hợp lý để mô phỏng không bị treo
    constraint c_delay {
        delay inside {[0:20]};
    }

    function new(string name = "uart_tr");
        this.name = name;
        this.stop_bits = 1;
    endfunction
endclass

`endif