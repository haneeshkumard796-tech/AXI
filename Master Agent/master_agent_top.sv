class master_agent_top extends uvm_env;
	`uvm_component_utils(master_agent_top)

	master_agent_config m_agt_cfgh;
	master_agent m_agt[];

	function new(string name = "master_agent_top",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(master_agent_config)::get(this,"","Master config",m_agt_cfgh))
			`uvm_fatal(get_type_name(),"Getting Master Config Failed")

		m_agt = new[m_agt_cfgh.no_of_agents];
		
		foreach(m_agt[i]) begin
			m_agt[i] = master_agent::type_id::create($sformatf("m_agt[%0d]",i),this);
			uvm_config_db #(bit)::set(this,$sformatf("m_agt[%0d]",i),"Agent_config",1'b1);
			uvm_config_db #(virtual AXI)::set(this,$sformatf("m_agt[%0d]*",i),"Master Interface",m_agt_cfgh.intrf);
		end
	endfunction
endclass