`ifndef COVERAGE_SV
`define COVERAGE_SV

`include "transaction.sv"
`include "apb_defines.sv"

// Note: this is a simple placeholder; you may want to integrate this more tightly with your clocking strategy.
class coverage_collector;
	string name;

	// Handles to monitored transactions
	mailbox #(apb_transaction) apb_mon_mb;
	mailbox #(uart_transaction) uart_mon_cov_mb;

	// Configuration handle
	uart_config cfg;

	// Events/Triggers
	event sample_cfg_e;

	// --------------------------------------------------------------------------
	// 1. APB Coverage Group
	// --------------------------------------------------------------------------
	covergroup cg_apb with function sample(apb_transaction tr);
		option.per_instance = 1;
		option.name = "cg_apb";

		cp_addr: coverpoint tr.addr {
			bins tx_reg   = {`UART_REG_TXDATA};
			bins rx_reg   = {`UART_REG_RXDATA};
			bins config_reg = {`UART_REG_CONFIG};
			bins status_reg = {`UART_REG_STATUS};
			bins control_reg = {`UART_REG_CONTROL};
		}

		cp_write: coverpoint tr.write {
			bins read  = {0};
			bins write = {1};
		}

		// Cross APB address with Read/Write operation
		cross_addr_rw: cross cp_addr, cp_write {
			// Ignore invalid combinations
			ignore_bins rx_write = binsof(cp_addr.rx_reg) && binsof(cp_write.write);
			ignore_bins status_write = binsof(cp_addr.status_reg) && binsof(cp_write.write);
			ignore_bins tx_read = binsof(cp_addr.tx_reg) && binsof(cp_write.read);
		}
	endgroup

	// --------------------------------------------------------------------------
	// 2. UART Configuration Coverage Group
	// --------------------------------------------------------------------------
	covergroup cg_uart_cfg;
		option.per_instance = 1;
		option.name = "cg_uart_cfg";

		cp_data_width: coverpoint cfg.data_width {
			bins width_5 = {5};
			bins width_6 = {6};
			bins width_7 = {7};
			bins width_8 = {8};
		}

		cp_parity_en: coverpoint cfg.parity_en {
			bins disabled = {0};
			bins enabled  = {1};
		}

		cp_parity_type: coverpoint cfg.parity_type {
			bins even = {0};
			bins odd  = {1};
		}

		cp_stop_bits: coverpoint cfg.stop_bits {
			bins stop_1 = {1};
			bins stop_2 = {2};
		}

		// Cross coverage of significant configuration combinations
		cross_all_cfg: cross cp_data_width, cp_parity_en, cp_parity_type, cp_stop_bits;
	endgroup

	// --------------------------------------------------------------------------
	// 3. UART Transaction Coverage Group (TX & RX)
	// --------------------------------------------------------------------------
	covergroup cg_uart_data with function sample(uart_transaction tr);
		option.per_instance = 1;
		option.name = "cg_uart_data";

		cp_dir: coverpoint tr.dir {
			bins tx = {uart_transaction::TX};
			bins rx = {uart_transaction::RX};
		}

		cp_data: coverpoint tr.data {
			bins zeros = {8'h00};
			bins ones  = {8'hFF};
			bins aa    = {8'hAA}; // 10101010
			bins five  = {8'h55}; // 01010101
			bins low   = {[0:10]};
			bins high  = {[245:255]};
			bins others = default;
		}

		// Cross direction with data patterns
		cross_dir_data: cross cp_dir, cp_data;
	endgroup

	// --------------------------------------------------------------------------
	// 4. Internal FSM Coverage (WHITEBOX)
	// --------------------------------------------------------------------------
	`ifdef WHITEBOX
	covergroup cg_internal_fsm;
		option.per_instance = 1;
		option.name = "cg_internal_fsm";

		// TX State Machine (Tpl_41)
		cp_tx_state: coverpoint tb_top.dut.Tpl_41 {
			bins idle     = {2'b00};
			bins start    = {2'b01};
			bins data     = {2'b10};
			bins par_stop = {2'b11};

			bins trans_idle_start = (2'b00 => 2'b01);
			bins trans_start_data = (2'b01 => 2'b10);
			bins trans_data_stop  = (2'b10 => 2'b11);
			bins trans_stop_idle  = (2'b11 => 2'b00);
		}

		// RX State Machine (Tpl_60)
		cp_rx_state: coverpoint tb_top.dut.Tpl_60 {
			bins start_check = {2'b00};
			bins data        = {2'b01};
			bins stop_check  = {2'b10};
			bins idle        = {2'b11};

			bins trans_idle_start = (2'b11 => 2'b00);
			bins trans_start_data = (2'b00 => 2'b01);
			bins trans_data_stop  = (2'b01 => 2'b10);
			bins trans_stop_idle  = (2'b10 => 2'b11);
		}
	endgroup
	`endif

	function new (
		string name = "coverage_collector",
		mailbox #(apb_transaction) apb_mon_mb,
		mailbox #(uart_transaction) uart_mon_cov_mb,
		uart_config cfg
	);
		this.name            = name;
		this.apb_mon_mb      = apb_mon_mb;
		this.uart_mon_cov_mb = uart_mon_cov_mb;
		this.cfg             = cfg;

		cg_apb       = new();
		cg_uart_cfg  = new();
		cg_uart_data = new();
		`ifdef WHITEBOX
		cg_internal_fsm = new();
		`endif
	endfunction

	task run();
		fork
			collect_apb();
			collect_uart();
			collect_internal_signals();
		join_none
	endtask

	task collect_apb();
		apb_transaction tr;
		forever begin
			apb_mon_mb.get(tr);
			cg_apb.sample(tr);

			// If we write to config register, sample the configuration coverage
			if (tr.write && tr.addr == `UART_REG_CONFIG) begin
				// Small delay to allow DUT to update if needed, though 'cfg' object 
				// in TB is updated by driver/generator usually. 
				// Here we assume 'cfg' object holds the intended verification config.
				#1; 
				cg_uart_cfg.sample();
			end
		end
	endtask

	task collect_uart();
		uart_transaction tr;
		forever begin
			uart_mon_cov_mb.get(tr);
			cg_uart_data.sample(tr);
		end
	endtask

	task collect_internal_signals();
		// Sample internal signals on clock edge
		forever begin
			@(posedge tb_top.clk);
			`ifdef WHITEBOX
			cg_internal_fsm.sample();
			`endif
		end
	endtask
endclass

`endif

