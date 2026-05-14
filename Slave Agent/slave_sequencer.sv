class slave_sequencer extends uvm_sequencer #(txn);
	`uvm_component_utils(slave_sequencer)

	function new(string name = "slave_sequencer",uvm_component parent);
		super.new(name,parent);
	endfunction

endclas