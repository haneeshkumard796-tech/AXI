class master_monitor extends uvm_monitor;
	`uvm_component_utils(master_monitor)
	
	uvm_analysis_port #(txn) m_ap;	

	function new(string name = "master_monitor",uvm_component parent);
		super.new(name,parent);
		m_ap = new("m_ap",this);
	endfunction
	
	virtual AXI intrf;
	virtual AXI.m_mon_mp mif;

	semaphore awc = new(1);
	semaphore wc = new(1);
	semaphore bc = new(1);
	semaphore arc = new(1);
	semaphore rc = new(1);

	semaphore awc_to_wc = new();
	semaphore wc_to_bc = new();
	semaphore arc_to_rc = new();
	
	txn q1[$],q2[$],q3[$],q4[$],q5[$];
	txn wtx, rtx;

	extern function void build_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	
	extern task collect_master_data();
	extern task collect_awc();
	extern task collect_wc(txn tx);
	extern task collect_bc(txn tx);
	extern task collect_arc();
	extern task collect_rc(txn tx);
	
endclass

	function void master_monitor::build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual AXI)::get(this,"","Master Interface",intrf))
			`uvm_fatal(get_type_name(),"Getting Master Interface Failed")
		mif = intrf;
	endfunction

	
	task master_monitor::run_phase(uvm_phase phase);
		forever begin
				collect_master_data();
		end
	endtask

	task master_monitor::collect_master_data();
		fork
			begin
				awc.get(1);
				collect_awc();
				awc.put(1);
				awc_to_wc.put(1);
			end

			begin
				wc.get(1);
				awc_to_wc.get(1);	
				collect_wc(q1.pop_front());
				wc.put(1);
				wc_to_bc.put(1);
			end
	
			begin
				bc.get(1);
				wc_to_bc.get(1);
				collect_bc(q2.pop_front());
				bc.put(1);
			end
		
			begin
				arc.get(1);
				collect_arc();
				arc.put(1);
				arc_to_rc.put(1);
			end

			begin
				rc.get(1);
				arc_to_rc.get(1);
				collect_rc(q4.pop_front());
				rc.put(1);
			end
		join	
	endtask

	task master_monitor::collect_awc();		
		wtx = txn::type_id::create("wtx");
		wait(mif.m_mon.AWVALID && mif.m_mon.AWREADY);
		wtx.awid = mif.m_mon.AWID;
		wtx.awaddr = mif.m_mon.AWADDR;
		wtx.awlen = mif.m_mon.AWLEN;
		wtx.awsize = mif.m_mon.AWSIZE;
		wtx.awburst = mif.m_mon.AWBURST;
		`uvm_info(get_type_name(),"\n\nMaster Write Address Channel",UVM_MEDIUM)
		
		q1.push_back(wtx);
		m_ap.write(wtx);	
		@(mif.m_mon);
	endtask

	task master_monitor::collect_wc(txn tx);
		`uvm_info(get_type_name(),"\n\nMaster Write data Channel",UVM_MEDIUM)
		tx.wdata = new[tx.awlen + 1];
		tx.wstrb = new[tx.awlen + 1];
		for(int i=0;i<=tx.awlen;i++) begin
			@(mif.m_mon);
			wait(mif.m_mon.WVALID && mif.m_mon.WREADY);
			tx.wid = mif.m_mon.WID;
			tx.wstrb[i] = mif.m_mon.WSTRB;
			case(tx.wstrb[i])
				4'b0001 : tx.wdata[i] = {24'd0,mif.m_mon.WDATA[7:0]};
				4'b0010 : tx.wdata[i] = {16'd0,mif.m_mon.WDATA[15:8],8'd0};
				4'b0100 : tx.wdata[i] = {8'd0,mif.m_mon.WDATA[23:16],16'd0};
				4'b1000 : tx.wdata[i] = {mif.m_mon.WDATA[31:24],24'd0};
				4'b0011 : tx.wdata[i] = {16'd0,mif.m_mon.WDATA[15:0]};
				4'b1100 : tx.wdata[i] = {mif.m_mon.WDATA[31:16],16'd0};
				4'b0110 : tx.wdata[i] = {8'd0,mif.m_mon.WDATA[23:8],8'd0};
				4'b1111 : tx.wdata[i] = mif.m_mon.WDATA;
				default : tx.wdata[i] = mif.m_mon.WDATA;
			endcase	
			@(mif.m_mon);
		end
		q2.push_back(tx);
		m_ap.write(tx);
		@(mif.m_mon);
	endtask
	
	task master_monitor::collect_bc(txn tx);
		wait(mif.m_mon.BVALID && mif.m_mon.BREADY);
		`uvm_info(get_type_name(),"\n\n Master Write response Channel",UVM_MEDIUM)
		tx.bid = mif.m_mon.BID;
		tx.bresp = mif.m_mon.BRESP;
		`uvm_info(get_type_name(),$sformatf("The Write Transaction Data \n%s",tx.sprint()),UVM_LOW)
				
		q3.push_back(tx);
		m_ap.write(q3.pop_front());
		@(mif.m_mon);
	endtask

	task master_monitor::collect_arc();	
		rtx = txn::type_id::create("rtx");
		wait(mif.m_mon.ARVALID && mif.m_mon.ARREADY);
		rtx.arid = mif.m_mon.ARID;
		rtx.araddr = mif.m_mon.ARADDR;
		rtx.arlen = mif.m_mon.ARLEN;
		rtx.arsize = mif.m_mon.ARSIZE;
		rtx.arburst = mif.m_mon.ARBURST;
				
		`uvm_info(get_type_name(),"\n\nMaster Read Address Channel",UVM_MEDIUM)

		q4.push_back(rtx);	
		m_ap.write(rtx);
		@(mif.m_mon);
	endtask

	task master_monitor::collect_rc(txn tx);
		tx.rdata = new[tx.arlen + 1];
		tx.rresp = new[tx.arlen + 1];
		foreach(tx.rdata[i]) begin
			@(mif.m_mon);
			wait(mif.m_mon.RVALID && mif.m_mon.RREADY);
			tx.rid = mif.m_mon.RID;
			tx.rdata[i] = mif.m_mon.RDATA;
			tx.rresp[i] = mif.m_mon.RRESP;
			@(mif.m_mon);
		end
		
		`uvm_info(get_type_name(),$sformatf("The Read Transaction Data \n%s",tx.sprint()),UVM_LOW);	
		
		q5.push_back(tx);
		m_ap.write(q5.pop_front());
		@(mif.m_mon);
	endtask
