class env extends uvm_env;
	`uvm_component_utils(env)
	
	env_config env_cfgh;
	master_agent_config m_agt_cfgh;
	slave_agent_config s_agt_cfgh;

	master_agent_top m_agt_top;
	slave_agent_top s_agt_top;
	scoreboard sb[];	
	
	function new(string name = "env",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(env_config)::get(this,"","Env config",env_cfgh))
			`uvm_fatal(get_type_name(),"Getting Env config object failed")
		
		sb = new[env_cfgh.no_of_masters];		
		foreach(sb[i]) begin
			sb[i]=scoreboard::type_id::create($sformatf("sb[%0d]",i),this);
		end
		m_agt_top = master_agent_top::type_id::create("m_agt_top",this);
		s_agt_top = slave_agent_top::type_id::create("s_agt_top",this);
			
		m_agt_cfgh = master_agent_config::type_id::create("m_agt_cfgh");
		s_agt_cfgh = slave_agent_config::type_id::create("s_agt_cfgh");
		
		m_agt_cfgh.intrf = env_cfgh.intrf;		
		s_agt_cfgh.intrf = env_cfgh.intrf;

		uvm_config_db #(master_agent_config)::set(this,"*","Master config",m_agt_cfgh);
		uvm_config_db #(slave_agent_config)::set(this,"*","Slave config",s_agt_cfgh);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		foreach(m_agt_top.m_agt[i]) begin
			m_agt_top.m_agt[i].m_monh.m_ap.connect(sb[i].m_fifo.analysis_export);	
			s_agt_top.s_agt[i].s_monh.s_ap.connect(sb[i].s_fifo.analysis_export);
		end	
	endfunction
endclass