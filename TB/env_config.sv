class env_config extends uvm_object;
	`uvm_object_utils(env_config)
	
	virtual AXI intrf; 

	int no_of_masters = 1; 
	int no_of_slaves = 1;

	function new(string name = "env_config");
		super.new(name);
	endfunction

endclass