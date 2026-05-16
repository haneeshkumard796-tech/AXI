class slave_monitor extends uvm_monitor;
	`uvm_component_utils(slave_monitor)

	uvm_analysis_port #(txn) s_ap;

	function new(string name = "slave_monitor",uvm_component parent);
		super.new(name,parent);
		s_ap = new("s_ap",this);
	endfunction

	virtual AXI intrf;
	virtual AXI.s_mon_mp sif;


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
	
	extern task collect_slave_data();
	extern task collect_awc();
	extern task collect_wc(txn tx);
	extern task collect_bc(txn tx);
	extern task collect_arc();
	extern task collect_rc(txn tx);

endclass

	function void slave_monitor::build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual AXI)::get(this,"","Slave Interface",intrf))
			`uvm_fatal(get_type_name(),"Getting Slave Interface Failed")
		sif = intrf;
	endfunction

	task slave_monitor::run_phase(uvm_phase phase);
		forever begin
				collect_slave_data();
		end
	endtask

	task slave_monitor::collect_slave_data();
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
		join_any	
	endtask

	task slave_monitor::collect_awc();	
		wtx = txn::type_id::create("wtx");
		@(sif.s_mon);
		wait(sif.s_mon.AWVALID && sif.s_mon.AWREADY);
		wtx.awid = sif.s_mon.AWID;
		wtx.awaddr = sif.s_mon.AWADDR;
		wtx.awlen = sif.s_mon.AWLEN;
		wtx.awsize = sif.s_mon.AWSIZE;
		wtx.awburst = sif.s_mon.AWBURST;
		
		q1.push_back(wtx);
		s_ap.write(wtx);
		@(sif.s_mon);
	endtask

	task slave_monitor::collect_wc(txn tx);
		tx.wdata = new[tx.awlen + 1];
		tx.wstrb = new[tx.awlen + 1];
		for(int i=0;i<=tx.awlen;i++) begin
			@(sif.s_mon);
			wait(sif.s_mon.WVALID && sif.s_mon.WREADY);
			tx.wid = sif.s_mon.WID;
			tx.wstrb[i] = sif.s_mon.WSTRB;
			case(tx.wstrb[i])
				4'b0001 : tx.wdata[i] = {24'd0,sif.s_mon.WDATA[7:0]};
				4'b0010 : tx.wdata[i] = {16'd0,sif.s_mon.WDATA[15:8],8'd0};
				4'b0100 : tx.wdata[i] = {8'd0,sif.s_mon.WDATA[23:16],16'd0};
				4'b1000 : tx.wdata[i] = {sif.s_mon.WDATA[31:24],24'd0};
				4'b0011 : tx.wdata[i] = {16'd0,sif.s_mon.WDATA[15:0]};
				4'b1100 : tx.wdata[i] = {sif.s_mon.WDATA[31:16],16'd0};
				4'b0110 : tx.wdata[i] = {8'd0,sif.s_mon.WDATA[23:8],8'd0};
				4'b1111 : tx.wdata[i] = sif.s_mon.WDATA;
				default : tx.wdata[i] = sif.s_mon.WDATA;
			endcase	
				@(sif.s_mon);
		end
		q2.push_back(tx);
		s_ap.write(tx);
		@(sif.s_mon);
	endtask
	
	task slave_monitor::collect_bc(txn tx);
		wait(sif.s_mon.BVALID && sif.s_mon.BREADY);
		tx.bid = sif.s_mon.BID;
		tx.bresp = sif.s_mon.BRESP;
	
		`uvm_info(get_type_name(),$sformatf("The Write Transaction Data \n%s",tx.sprint()),UVM_LOW)
			
		q3.push_back(tx);
		s_ap.write(q3.pop_front());
		@(sif.s_mon);
	endtask

	task slave_monitor::collect_arc();
		rtx = txn::type_id::create("rtx");
		@(sif.s_mon);		
		wait(sif.s_mon.ARVALID && sif.s_mon.ARREADY);
		rtx.arid = sif.s_mon.ARID;
		rtx.araddr = sif.s_mon.ARADDR;
		rtx.arlen = sif.s_mon.ARLEN;
		rtx.arsize = sif.s_mon.ARSIZE;
		rtx.arburst = sif.s_mon.ARBURST;
		
		q4.push_back(rtx);	
		s_ap.write(rtx);
		@(sif.s_mon);
	endtask

	task slave_monitor::collect_rc(txn tx);
		tx.rdata = new[tx.arlen + 1];
		tx.rresp = new[tx.arlen + 1];
			foreach(tx.rdata[i]) begin
			@(sif.s_mon);
			wait(sif.s_mon.RVALID && sif.s_mon.RREADY);
			tx.rid = sif.s_mon.RID;
			tx.rdata[i] = sif.s_mon.RDATA;
			tx.rresp[i] = sif.s_mon.RRESP;
			@(sif.s_mon);
		end
		`uvm_info(get_type_name(),$sformatf("The Read Transaction Data \n%s",tx.sprint()),UVM_LOW);
		q5.push_back(tx);
		s_ap.write(q5.pop_front());
		@(sif.s_mon);
	endtask
