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
       bit [`APB_DATA_WIDTH-1:0]  rdata; // Biến này chứa kết quả đọc về

  string name;

  // Ràng buộc địa chỉ hợp lệ
  constraint c_default {
    addr inside { `UART_REG_TXDATA,
                  `UART_REG_RXDATA,
                  `UART_REG_CONFIG,  // <-- QUAN TRỌNG: Phải có thanh ghi cấu hình 
                  `UART_REG_CONTROL, // 0xC
                  `UART_REG_STATUS   // 0x10 [cite: 153]
                };
  }
  
  // Ràng buộc địa chỉ phải chia hết cho 4 (Word Aligned)
  constraint c_align {
    addr[1:0] == 2'b00;
  }

  function new(string name = "apb_tr");
    this.name = name;
    this.strb = 4'hF;
  endfunction
  
  // Hàm hiển thị hỗ trợ debug
  function void display(string tag="");
     $display("[%s] %s Addr=%h Data=%h", tag, (write ? "WR" : "RD"), addr, (write ? wdata : rdata));
  endfunction
endclass


// ---------------------------------------------------------
// 2. UART TRANSACTION
// ---------------------------------------------------------
class uart_transaction;
  rand bit [7:0] data;
  rand bit       parity_error; // Cờ để tiêm lỗi Parity (Error Injection)
  rand int       stop_bits;
  rand int       delay;        // Độ trễ giữa các gói tin (để test RX)

  string name;

  // Ràng buộc Stop bits chỉ được là 1 hoặc 2 theo Spec 
  constraint c_stop_bits {
    stop_bits inside {1, 2};
  }

  // Ràng buộc delay hợp lý (ví dụ từ 0 đến 20 chu kỳ bit)
  constraint c_delay {
    delay inside {[0:20]};
  }

  function new(string name = "uart_tr");
    this.name = name;
    this.stop_bits = 1;
    this.parity_error = 0;
  endfunction
  
  function void display(string tag="");
     $display("[%s] UART Byte=%h (Stop=%0d)", tag, data, stop_bits);
  endfunction
endclass

`endif