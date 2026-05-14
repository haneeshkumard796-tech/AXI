class master_agent extends uvm_agent;
	`uvm_component_utils(master_agent)

	bit is_active;
	
	master_sequencer m_seqrh;
	master_driver m_drvh;
	master_monitor m_monh;
	
	function new(string name = "master_agent",uvm_component parent);
		super.new(name,parent);
	endfunction

	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(bit)::get(this,"","Agent_config",is_active))
			`uvm_fatal(get_type_name(),"Gettign Agent  Failed")
	
		if(is_active == 1'b1) begin
			m_seqrh =  master_sequencer::type_id::create("m_seqrh",this);
			m_drvh =  master_driver::type_id::create("m_drvh",this);
		end
			m_monh =  master_monitor::type_id::create("m_monh",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		if(is_active == 1'b1) begin
			m_drvh.seq_item_port.connect(m_seqrh.seq_item_export);
		end
	endfunction
endclass