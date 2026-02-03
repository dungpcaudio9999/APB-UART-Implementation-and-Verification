`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV
`include "uart_if.sv"
`include "transaction.sv"

class uart_driver;
	string name;
	virtual uart_if.TB_DRV vif;
	uart_config cfg;
	mailbox #(uart_transaction) in_mb;
	real bit_period;

	function new(string name, virtual uart_if.TB_DRV vif, uart_config cfg, mailbox #(uart_transaction) in_mb);
		this.name=name; this.vif=vif; this.cfg=cfg; this.in_mb=in_mb;
		this.bit_period = (1000000000.0 / cfg.baud_rate);
	endfunction

	task run();
		uart_transaction tr;
		vif.cb_drv.rx <= 1; vif.cb_drv.cts_n <= 0;
		forever begin
			in_mb.get(tr);
			// Flow control
			while(vif.cb_drv.rts_n) @(vif.cb_drv);

			// Start bit
			vif.cb_drv.rx <= 0; #(bit_period);
		  
			  // Data + Parity
			begin
				bit p_bit = 0;
				for(int i=0; i<cfg.data_width; i++) begin
					vif.cb_drv.rx <= tr.data[i];
					if(cfg.parity_en) p_bit ^= tr.data[i];
					#(bit_period);
				end
				$display("[FLOW_DRV] UART Driving RX Byte: %h", tr.data);
				if(cfg.parity_en) begin
					if(cfg.parity_type) p_bit = ~p_bit; // Odd
					if(tr.parity_error) p_bit = ~p_bit; // Inject Error
					vif.cb_drv.rx <= p_bit; #(bit_period);
				end
			end
			  
			// Stop bit
			vif.cb_drv.rx <= 1; #(bit_period * cfg.stop_bits);
			#(tr.delay * bit_period);
		end
	endtask
endclass
`endif