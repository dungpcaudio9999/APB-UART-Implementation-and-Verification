`ifndef TRANSACTION_SV
`define TRANSACTION_SV

`include "apb_defines.sv"

// ---------------------------------------------------------
// 0. UART CONFIGURATION
// ---------------------------------------------------------
class uart_config;
	// Parameters
	rand int data_width;      // 5, 6, 7, 8
	rand bit parity_en;       // 0: Disable, 1: Enable
	rand bit parity_type;     // 0: Even, 1: Odd
	rand int stop_bits;       // 1, 2

	real baud_rate = 115200.0; // Default baud rate

	// Constraints
	constraint c_data_width {
		data_width inside {5, 6, 7, 8};
	}

	constraint c_stop_bits {
		stop_bits inside {1, 2};
	}

	function new();
		// Defaults matching the current hardcoded behavior if not randomized
		data_width  = 8;
		parity_en   = 0;
		parity_type = 0;
		stop_bits   = 1;
	endfunction

	function void display(string tag="");
		$display("[%s] Config: Data=%0d, Parity=%s (%s), Stop=%0d", tag, data_width, (parity_en ? "On" : "Off"), (parity_type ? "Odd" : "Even"), stop_bits);
	endfunction

endclass

// ---------------------------------------------------------
// 1. APB TRANSACTION
// ---------------------------------------------------------
class apb_transaction;
    // Enum to control the type of transaction
    typedef enum bit [2:0] {
        ANY      = 0, // Random Address
        TX_WRITE = 1, // Only Write TX Data
        RX_READ  = 2, // Only Read RX Data
        CONFIG   = 3, // Only Write Config
        STATUS   = 4  // Only Read Status
    } kind_e;

    rand kind_e                     trans_kind; // Control Knob

	rand bit                        write;
	rand bit [`APB_ADDR_WIDTH-1:0]  addr;
	rand bit [3:0]                  strb;
	rand bit [`APB_DATA_WIDTH-1:0]  wdata;
		bit [`APB_DATA_WIDTH-1:0]  rdata; // Biến này chứa kết quả đọc về

	string name;

	// Default Constraint: Address within valid range
	constraint c_default {
		addr inside { 
			`UART_REG_TXDATA,
			`UART_REG_RXDATA,
			`UART_REG_CONFIG, 
			`UART_REG_CONTROL, 
			`UART_REG_STATUS
		};
	}
  
	// Constraint: Address must be Word Aligned
	constraint c_align {
		addr[1:0] == 2'b00;
	}

    // Constraint: Control Logic based on 'trans_kind'
    constraint c_kind_logic {
        if (trans_kind == TX_WRITE) {
            write == 1;
            addr == `UART_REG_TXDATA;
        }
        
        if (trans_kind == RX_READ) {
            write == 0;
            addr == `UART_REG_RXDATA;
        }
        
        if (trans_kind == CONFIG) {
            write == 1;
            addr == `UART_REG_CONFIG;
        }
        
        if (trans_kind == STATUS) {
            write == 0;
            addr == `UART_REG_STATUS;
        }
        // ANY allows c_default to decide, no extra restrictions
    }

    // Soft constraint to default to ANY if not specified
    constraint c_kind_default {
        soft trans_kind == ANY;
    }

	function new(string name = "apb_tr");
		this.name = name;
		this.strb = 4'hF;
	endfunction

	// Hàm hiển thị hỗ trợ debug
	function void display(string tag="");
		$display("[%s] Kind=%s %s Addr=%h Data=%h", tag, trans_kind.name(), (write ? "WR" : "RD"), addr, (write ? wdata : rdata));
	endfunction
endclass


// ---------------------------------------------------------
// 2. UART TRANSACTION
// ---------------------------------------------------------
class uart_transaction;
	typedef enum {RX, TX} dir_e;
	dir_e          dir;
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
		delay inside {[0:1000]};
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
