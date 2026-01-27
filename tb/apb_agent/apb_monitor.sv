`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV
`include "apb_if.sv"
`include "transaction.sv"

class apb_monitor;
	string name;
	virtual apb_if.TB_MON vif;
	mailbox #(apb_transaction) out_mb;     // Cho Scoreboard
	mailbox #(apb_transaction) cov_mb;     // Cho Coverage

	function new (
		string name,
		virtual apb_if.TB_MON vif,
		mailbox #(apb_transaction) out_mb,
		mailbox #(apb_transaction) cov_mb
	);
		this.name = name;
		this.vif = vif;
		this.out_mb = out_mb;
		this.cov_mb = cov_mb;
	endfunction

	task run();
		apb_transaction tr;
		forever begin
			@(vif.cb_mon);
			// FIX: Bắt tín hiệu khi handshake hoàn tất (Ready & Enable & Sel)
			if (vif.cb_mon.psel && vif.cb_mon.penable && vif.cb_mon.pready) begin
				tr = new("apb_mon_tr");
				tr.write = vif.cb_mon.pwrite;
				tr.addr  = vif.cb_mon.paddr;
				tr.wdata = vif.cb_mon.pwdata;
				if (!tr.write) tr.rdata = vif.cb_mon.prdata;

				        $display("[FLOW_MON] APB Captured Addr=%h Data=0x%02h", tr.addr, (tr.write ? tr.wdata[7:0] : tr.rdata[7:0]));

				// Gửi cho cả 2 nơi 
				out_mb.put(tr); 

				// FIX: Copy transaction cho coverage để tránh tranh chấp
				begin
					apb_transaction tr_cov = new tr; 
					cov_mb.put(tr_cov);
				end
			end
		end
	endtask
endclass
`endif