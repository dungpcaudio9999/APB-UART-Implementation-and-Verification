`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV
`include "apb_if.sv"
`include "transaction.sv"

class apb_driver;
	string name;
	virtual apb_if.TB_DRV vif;
	mailbox #(apb_transaction) in_mb;

	function new (
		string name,
		virtual apb_if.TB_DRV vif,
		mailbox #(apb_transaction) in_mb
	);
		this.name=name; this.vif=vif; this.in_mb=in_mb;
	endfunction

	task run();
		apb_transaction tr;
		vif.cb_drv.psel <= 0; vif.cb_drv.penable <= 0;
		forever begin
			in_mb.get(tr);
			@(vif.cb_drv);
			vif.cb_drv.psel <= 1; vif.cb_drv.pwrite <= tr.write; 
			vif.cb_drv.paddr <= tr.addr; vif.cb_drv.pwdata <= tr.wdata;
			if(tr.write) $display("[FLOW_DRV] APB Driving WRITE Addr=%h Data=%h", tr.addr, tr.wdata);
			else $display("[FLOW_DRV] APB Driving READ Addr=%h", tr.addr);
			@(vif.cb_drv);
			vif.cb_drv.penable <= 1;
			do @(vif.cb_drv); while(!vif.cb_drv.pready);
			if(!tr.write) tr.rdata = vif.cb_drv.prdata;
			vif.cb_drv.psel <= 0; vif.cb_drv.penable <= 0;
		end
	endtask
endclass
`endif