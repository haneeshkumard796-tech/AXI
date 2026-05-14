class slave_agent_top extends uvm_env;
	`uvm_component_utils(slave_agent_top)

	slave_agent_config s_agt_cfgh;
	slave_agent s_agt[];

	function new(string name = "slave_agent_top",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(slave_agent_config)::get(this,"","Slave config",s_agt_cfgh))
			`uvm_fatal(get_type_name(),"Getting Slave Config Failed")

		s_agt = new[s_agt_cfgh.no_of_agents];
		
		foreach(s_agt[i]) begin
			s_agt[i] = slave_agent::type_id::create($sformatf("s_agt[%0d]",i),this);
			uvm_config_db #(bit)::set(this,$sformatf("s_agt[%0d]",i),"Agent_config",1'b1);
			uvm_config_db #(virtual AXI)::set(this,$sformatf("s_agt[%0d]*",i),"Slave Interface",s_agt_cfgh.intrf);
		end
	endfunction
endclass