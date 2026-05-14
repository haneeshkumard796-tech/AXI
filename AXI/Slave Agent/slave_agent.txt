class slave_agent extends uvm_agent;
	`uvm_component_utils(slave_agent)

	bit is_active;
	
	slave_sequencer s_seqrh;
	slave_driver s_drvh;
	slave_monitor s_monh;
	
	function new(string name = "slave_agent",uvm_component parent);
		super.new(name,parent);
	endfunction

	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(bit)::get(this,"","Agent_config",is_active))
			`uvm_fatal(get_type_name(),"Gettign Agent  Failed")
	
		if(is_active == 1'b1) begin
			s_seqrh =  slave_sequencer::type_id::create("s_seqrh",this);
			s_drvh =  slave_driver::type_id::create("s_drvh",this);
		end
			s_monh =  slave_monitor::type_id::create("s_monh",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if(is_active == 1'b1) begin
			s_drvh.seq_item_port.connect(s_seqrh.seq_item_export);
		end
	endfunction
endclass