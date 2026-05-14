class slave_agent_config extends uvm_object;
	`uvm_object_utils(slave_agent_config)
	
	int no_of_agents = 1;	
	
	virtual AXI intrf;
	function new(string name = "slave_agent_config");
		super.new(name);
	endfunction
endclass
