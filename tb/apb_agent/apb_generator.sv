`ifndef APB_GENERATOR_SV
`define APB_GENERATOR_SV
`include "transaction.sv"

class apb_generator;
	mailbox #(apb_transaction) out_mb;
	apb_transaction blueprint;
	int num_transactions;

	function new (
		string name,
		mailbox #(apb_transaction) out_mb,
		int n=100
	);
		this.out_mb = out_mb; this.num_transactions = n;
		this.blueprint = new("blueprint");
	endfunction

	virtual task generate_batch(int n);
		apb_transaction tr;
		for(int i=0; i<n; i++) begin
			assert(blueprint.randomize());
			tr = new blueprint;
			out_mb.put(tr);
		end
	endtask

	virtual task run();
		if(num_transactions > 0) generate_batch(num_transactions);
	endtask
endclass
`endif