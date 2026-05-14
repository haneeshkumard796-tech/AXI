class base_test extends uvm_test;
	`uvm_component_utils(base_test)
	env envh;
	env_config env_cfgh;
	function new(string name = "base_test",uvm_component parent);
		super.new(name,parent);
	endfunction
		

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env_cfgh = env_config::type_id::create("env_cfgh");
		envh = env::type_id::create("env",this);
		
		if(!uvm_config_db #(virtual AXI) :: get(this,"","Interface",env_cfgh.intrf))
			`uvm_fatal(get_type_name(),"Getting interface failed")
		
		uvm_config_db #(env_config)::set(this,"env","Env config",env_cfgh);
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
			super.end_of_elaboration_phase(phase);
			uvm_top.print_topology();
	endfunction

endclass

class fixed_test extends base_test;
	`uvm_component_utils(fixed_test)

	fixed_seq f_seqh1;	

	function new(string name = "fixed_test",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		phase.raise_objection(this);
				f_seqh1 = fixed_seq::type_id::create("f_seqh1");
				f_seqh1.start(envh.m_agt_top.m_agt[0].m_seqrh);
		phase.drop_objection(this);
	endtask

endclass

class incr_test extends base_test;
	`uvm_component_utils(incr_test)

	incr_seq f_seqh1;	

	function new(string name = "incr_test",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		phase.raise_objection(this);
				f_seqh1 = incr_seq::type_id::create("f_seqh1");
				f_seqh1.start(envh.m_agt_top.m_agt[0].m_seqrh);
		phase.drop_objection(this);
	endtask
	
endclass

class wrap_test extends base_test;
	`uvm_component_utils(wrap_test)

	wrap_seq f_seqh1;	

	function new(string name = "wrap_test",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		phase.raise_objection(this);
				f_seqh1 = wrap_seq::type_id::create("f_seqh1");
				f_seqh1.start(envh.m_agt_top.m_agt[0].m_seqrh);
		phase.drop_objection(this);
	endtask
		
endclass