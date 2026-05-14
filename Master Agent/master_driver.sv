class master_driver extends uvm_driver #(txn);
	`uvm_component_utils(master_driver)
	
	function new(string name = "master_driver",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	
	virtual AXI intrf;
	virtual AXI.m_drv_mp mif;
	
	semaphore awc = new(1);
	semaphore wc = new(1);
	semaphore bc = new(1);
	semaphore arc = new(1);
	semaphore rc = new(1);

	semaphore awc_to_wc = new();
	semaphore wc_to_bc = new();
	semaphore arc_to_rc = new();

	txn q1[$],q2[$],q3[$],q4[$],q5[$];
	

	extern function void build_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);	
	extern task send_to_slave();
	
	extern task awc_drive(txn req);
	extern task wc_drive(txn req);
	extern task bc_drive(txn req);
	extern task arc_drive(txn req);
	extern task rc_drive(txn req);
endclass

	function void master_driver::build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual AXI)::get(this,"","Master Interface",intrf))
			`uvm_fatal(get_type_name(),"Getting Master Interface Failed")
		mif = intrf;
	endfunction

	task master_driver::run_phase(uvm_phase phase);	
		super.run_phase(phase);
		
		forever begin
			`uvm_info(get_type_name(),"Blocking method get_next_item",UVM_MEDIUM)
			seq_item_port.get_next_item(req);
			q1.push_back(req);
			q2.push_back(req);
			q3.push_back(req);
			q4.push_back(req);
			q5.push_back(req);
			send_to_slave();
			seq_item_port.item_done();
		end
	endtask

	task master_driver::send_to_slave();
		fork
			begin
				awc.get(1);
				awc_drive(q1.pop_front());		//write address channel
				awc.put(1);
				awc_to_wc.put(1);
			end

			begin
				wc.get(1);
				awc_to_wc.get(1);	
				wc_drive(q2.pop_front());		//write data channel
				wc.put(1);
				wc_to_bc.put(1);
			end
			
			begin
				bc.get(1);
				wc_to_bc.get(1);
				bc_drive(q3.pop_front());		//write response channel
				bc.put(1);
			end

			begin
				arc.get(1);
				arc_drive(q4.pop_front());		//read address channel
				arc.put(1);
				arc_to_rc.put(1);
			end
		
			begin
				rc.get(1);
				arc_to_rc.get(1);
				rc_drive(q5.pop_front());		//read data channel
				rc.put(1);
			end
		join
	endtask

	task master_driver::awc_drive(txn req);
		mif.m_drv.AWID <= req.awid;
		mif.m_drv.AWADDR <= req.awaddr;
		mif.m_drv.AWLEN <= req.awlen;
		mif.m_drv.AWSIZE <= req.awsize;
		mif.m_drv.AWBURST <= req.awburst;
		mif.m_drv.AWVALID <= 1'b1;
		`uvm_info(get_type_name(),"\n\nWrite Address Channel",UVM_MEDIUM)
		
		`uvm_info(get_type_name(),$sformatf("\n\nWrite Address and Control signals driven are \n AWID : %0d \n Address : %0d \n AWLEN : %0d \n AWSIZE : %0d \n AWBURST : %0d",req.awid,req.awaddr,req.awlen,req.awsize,req.awburst),UVM_LOW)
			
		`uvm_info(get_type_name(),"Waiting for AWREADY signal",UVM_MEDIUM)
		@(mif.m_drv);
		wait(mif.m_drv.AWREADY);
		mif.m_drv.AWVALID <= 1'b0;
		`uvm_info(get_type_name(),"Got AWREADY signal",UVM_MEDIUM)
		repeat($urandom_range(1,5))
		@(mif.m_drv);
	endtask

	task master_driver::wc_drive(txn req);
		mif.m_drv.WID <= req.wid;
		`uvm_info(get_type_name(),"\n\nWrite Data Channel",UVM_MEDIUM)
		for(int i=0;i<=(req.awlen);i++) begin
			repeat($urandom_range(1,2))
			@(mif.m_drv);
			mif.m_drv.WDATA <=  req.wdata[i];
			mif.m_drv.WSTRB <= req.wstrb[i];	
			mif.m_drv.WVALID <= 1'b1;
			`uvm_info(get_type_name(),"Asserted WVALID signal",UVM_MEDIUM)
			`uvm_info(get_type_name(),$sformatf("\nWDATA[%0d] : %0h | WSTRB[%0d] : %0h",i,req.wdata[i],i,req.wstrb[i]),UVM_LOW)
			if(i == req.awlen)
				mif.m_drv.WLAST <= 1'b1;
			else
				mif.m_drv.WLAST <= 1'b0;	
			`uvm_info(get_type_name(),"Waiting for WREADY signal",UVM_MEDIUM)
			@(mif.m_drv);
			wait(mif.m_drv.WREADY);
				mif.m_drv.WVALID <= 1'b0;
			`uvm_info(get_type_name(),"Got WREADY signal, deasserting WVALID",UVM_MEDIUM)
			
		end
			mif.m_drv.WLAST <= 1'b0;
			mif.m_drv.WID <= 4'd0;
			mif.m_drv.WVALID <= 1'b0;
			mif.m_drv.WSTRB <= 4'd0;
			repeat($urandom_range(1,5))
			@(mif.m_drv);
	endtask

	task master_driver::bc_drive(txn req);
		mif.m_drv.BREADY <= 1'b1;
		`uvm_info(get_type_name(),"\n\nWrite Response Channel, asserted BREADY and Waiting for BVALID",UVM_MEDIUM)
		
		@(mif.m_drv);
		wait(mif.m_drv.BVALID);
		`uvm_info(get_type_name(),"Got BVLAID signal, deasserting BREADY",UVM_MEDIUM)
		
		req.bresp = mif.m_drv.BRESP;
		`uvm_info(get_type_name(),$sformatf("Slave Response : %0d",req.bresp),UVM_MEDIUM)
		
		mif.m_drv.BREADY <= 1'b0;
		repeat($urandom_range(2,5))	
		@(mif.m_drv);

	endtask

	task master_driver::arc_drive(txn req);
		mif.m_drv.ARID <= req.arid;
		mif.m_drv.ARADDR <= req.araddr;
		mif.m_drv.ARLEN <= req.arlen;
		mif.m_drv.ARSIZE <= req.arsize;
		mif.m_drv.ARBURST <= req.arburst;
		mif.m_drv.ARVALID <= 1'b1;
		`uvm_info(get_type_name(),"\n\nRead Address Channel",UVM_MEDIUM)
		
		`uvm_info(get_type_name(),$sformatf("\n\nRead Address and Control signal driven are\n ARID : %0d \n ARADDRESS : %0d \n ARLEN : %0d \n ARSIZE : %0d \n ARBURST : %0d",req.arid,req.araddr,req.arlen,req.arsize,req.arburst),UVM_LOW)
		
		`uvm_info(get_type_name(),"Waiting for ARREADY signal",UVM_MEDIUM)
		@(mif.m_drv);
		wait(mif.m_drv.ARREADY);
		
		mif.m_drv.ARVALID <= 1'b0;
		`uvm_info(get_type_name(),"Got ARREADY signal",UVM_MEDIUM)
		repeat($urandom_range(1,5))
		@(mif.m_drv);
	endtask
	
	task master_driver::rc_drive(txn req);	
		for(int i=0;i<=req.arlen;i++) begin
		mif.m_drv.RREADY <= 1'b1;
		@(mif.m_drv);
		wait(mif.m_drv.RVALID);
		mif.m_drv.RREADY <= 1'b0;
		
		repeat($urandom_range(1,5))
		@(mif.m_drv);
		end
	endtask
