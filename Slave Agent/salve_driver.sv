class slave_driver extends uvm_driver #(txn);
	`uvm_component_utils(slave_driver)

	function new(string name = "slave_driver",uvm_component parent);
		super.new(name,parent);
	endfunction

	virtual AXI intrf;
	virtual AXI.s_drv_mp sif;

	semaphore awc = new(1);
	semaphore wc = new(1);
	semaphore bc = new(1);
	semaphore arc = new(1);
	semaphore rc = new(1);

	semaphore awc_to_wc = new();
	semaphore wc_to_bc = new();
	semaphore arc_to_rc = new();

	txn q1[$],q2[$],q3[$],q4[$],q5[$];
	txn req,req1,req2;

	extern function void build_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);	
	extern task send_to_master();
	
	extern task awc_drive();
	extern task wc_drive(txn tx);
	extern task bc_drive(txn tx);
	extern task arc_drive();
	extern task rc_drive(txn req);

endclass

	function void slave_driver::build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual AXI)::get(this,"","Slave Interface",intrf))
			`uvm_fatal(get_type_name(),"Getting Slave Interface Failed")
		sif = intrf;
	endfunction

	task slave_driver::run_phase(uvm_phase phase);	
		super.run_phase(phase);	
			req = txn::type_id::create("req");
		forever begin
			`uvm_info(get_type_name(),"Blocking method get_next_item",UVM_MEDIUM)
			send_to_master();
		end
	endtask

	task slave_driver::send_to_master();
		fork
			begin
				awc.get(1);
				awc_drive();	//write address channel					
				awc.put(1);
				awc_to_wc.put(1);
			end

			begin
				wc.get(1);
				awc_to_wc.get(1);	
				wc_drive(q1.pop_front());		//write data channel
				wc.put(1);
				wc_to_bc.put(1);
			end
			
			begin
				bc.get(1);
				wc_to_bc.get(1);
				bc_drive(q2.pop_front());		//write response channel
				bc.put(1);
			end
			begin
				arc.get(1);
				arc_drive();		//read address channel
				arc.put(1);
				arc_to_rc.put(1);
			end
		
			begin
				rc.get(1);
				arc_to_rc.get(1);
				rc_drive(q3.pop_front());	
				rc.put(1);
			end
		join_any
	endtask


	task slave_driver::awc_drive();
		req1 = txn::type_id::create("req1");
		sif.s_drv.AWREADY <= 1'b1;
		@(sif.s_drv);
		wait(sif.s_drv.AWVALID);
		sif.s_drv.AWREADY <= 1'b0;
		req1.awid = sif.s_drv.AWID;
		req1.awlen = sif.s_drv.AWLEN;
		q1.push_back(req1);	
		repeat($urandom_range(2,5))
		@(sif.s_drv);
	endtask

	task slave_driver::wc_drive(txn tx);
		`uvm_info(get_type_name(),$sformatf("write data channel tx is :\n%s",tx.sprint()),UVM_MEDIUM)
		for(int i=0;i<=tx.awlen;i++) begin
		sif.s_drv.WREADY <= 1'b1;
		@(sif.s_drv);
		wait(sif.s_drv.WVALID);
		sif.s_drv.WREADY <= 1'b0;
		repeat(2)
		@(sif.s_drv);
		end
		q2.push_back(tx);
	endtask


	task slave_driver::bc_drive(txn tx);
		`uvm_info(get_type_name(),$sformatf("write response channel tx is :\n%s",tx.sprint()),UVM_MEDIUM)

		tx.bid = tx.awid;
		sif.s_drv.BID <= tx.bid;
		sif.s_drv.BRESP <= 2'd0;
		sif.s_drv.BVALID <= 1'b1;
		@(sif.s_drv);

		wait(sif.s_drv.BREADY);
		sif.s_drv.BRESP <= 2'dz;
		sif.s_drv.BVALID <= 1'b0;
		sif.s_drv.BID <= 2'd0;
		repeat($urandom_range(2,5))
		@(sif.s_drv);
	endtask

	task slave_driver::arc_drive();
		req2 = txn::type_id::create("req2");
		sif.s_drv.ARREADY <= 1'b1;
		@(sif.s_drv);
		wait(sif.s_drv.ARVALID);
		sif.s_drv.ARREADY <= 1'b0;
		req2.arid = sif.s_drv.ARID;
		req2.araddr = sif.s_drv.ARADDR;
		req2.arlen = sif.s_drv.ARLEN;
		req2.arsize = sif.s_drv.ARSIZE;
		req2.arburst = sif.s_drv.ARBURST;

		q3.push_back(req2);
		repeat($urandom_range(2,5))
		@(sif.s_drv);
	
	endtask

	task slave_driver::rc_drive(txn req);
		`uvm_info(get_type_name(),$sformatf("read data :\n%s",req.sprint()),UVM_MEDIUM)
		sif.s_drv.RID <= req.arid;	
		for(int i=0;i<=(req.arlen);i++) begin
			repeat($urandom_range(1,2))
			@(sif.s_drv);
			sif.s_drv.RDATA <=  $urandom();
			sif.s_drv.RVALID <= 1'b1;
			sif.s_drv.RRESP <= 2'd0;;
			`uvm_info(get_type_name(),$sformatf("\nRDATA[%0d] : %0h | RRESP[%0d] : 0",i,req.rdata[i],i),UVM_MEDIUM)
			if(i == (req.arlen)) begin
				sif.s_drv.RLAST <= 1'b1;
				`uvm_info(get_type_name(),"\n\nAsserting RLAST",UVM_LOW)
			end
			else
				sif.s_drv.RLAST <= 1'b0;	
			@(sif.s_drv);
			wait(sif.s_drv.RREADY);
				sif.s_drv.RVALID <= 1'b0;
				`uvm_info(get_type_name(),"\n\Got RREADY",UVM_LOW)
			@(sif.s_drv);
		end
			sif.s_drv.RLAST <= 1'b0;	
			sif.s_drv.RID <= 4'd0;
			sif.s_drv.RVALID <= 1'b0;
			sif.s_drv.RRESP <= 2'dz;	
			repeat($urandom_range(2,5))
			@(sif.s_drv);

	endtask
