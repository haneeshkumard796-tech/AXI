interface AXI(input bit ACLK);

	import uvm_pkg::*;
	`include "uvm_macros.svh"
	
	//write address channel
	logic [3:0]AWID;
	logic [31:0]AWADDR;
	logic [3:0]AWLEN;
	logic [2:0]AWSIZE;
	logic [1:0]AWBURST;
	logic AWVALID;
	logic AWREADY;

	//write data channel
	logic [3:0]WID;
	logic [31:0]WDATA;
	logic [3:0]WSTRB;
	logic WLAST;
	logic WVALID;
	logic WREADY;

	//write response channel
	logic [3:0]BID;
	logic [1:0]BRESP;
	logic BVALID;
	logic BREADY;

	//read address channel
	logic [3:0]ARID;
	logic [31:0]ARADDR;
	logic [3:0]ARLEN;
	logic [2:0]ARSIZE;
	logic [1:0]ARBURST;
	logic ARVALID;
	logic ARREADY;

	//read data channel
	logic [3:0]RID;
	logic [31:0]RDATA;
	logic [1:0]RRESP;
	logic RLAST;
	logic RVALID;
	logic RREADY;

	
	clocking m_drv@(posedge ACLK);
		output AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID;
		input AWREADY;
		
		output WID,WDATA,WSTRB,WLAST,WVALID;
		input WREADY;

		output BREADY;
		input BID,BRESP,BVALID;

		output ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID;
		input ARREADY;
		
		output RREADY;
		input RID,RDATA,RRESP,RLAST,RVALID;
	endclocking

	clocking m_mon@(posedge ACLK);
		input AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID;
		input AWREADY;
		
		input WID,WDATA,WSTRB,WLAST,WVALID;
		input WREADY;

		input BREADY;
		input BID,BRESP,BVALID;

		input ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID;
		input ARREADY;
		
		input RREADY;
		input RID,RDATA,RRESP,RLAST,RVALID;
	endclocking

	clocking s_drv@(posedge ACLK);
		input AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID;
		output AWREADY;
		
		input WID,WDATA,WSTRB,WLAST,WVALID;
		output WREADY;

		input BREADY;
		output BID,BRESP,BVALID;

		input ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID;
		output ARREADY;
		
		input RREADY;
		output RID,RDATA,RRESP,RLAST,RVALID;
	endclocking
	
	clocking s_mon@(posedge ACLK);
		input AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID;
		input AWREADY;
		
		input WID,WDATA,WSTRB,WLAST,WVALID;
		input WREADY;

		input BREADY;
		input BID,BRESP,BVALID;

		input ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID;
		input ARREADY;
		
		input RREADY;
		input RID,RDATA,RRESP,RLAST,RVALID;
	endclocking

	property p1;
		@(posedge ACLK) (AWVALID && AWREADY) |=> !AWREADY;
	endproperty	
	
	property p2;
		@(posedge ACLK) (WVALID && WREADY) |=> !WREADY;
	endproperty	
	
	property p3;
		@(posedge ACLK) (BVALID && BREADY) |=> !BREADY;
	endproperty	
	
	property p4;
		@(posedge ACLK) (ARVALID && ARREADY) |=> !ARREADY;
	endproperty	
	
	property p5;
		@(posedge ACLK) (RVALID && RREADY) |=> !RREADY;
	endproperty	

	property p6;
		@(posedge ACLK) WLAST && !(BVALID) |=> ##[0:$]BVALID;
	endproperty

	property p7;
		@(posedge ACLK) first_match(AWVALID ##[1:$]AWREADY ##[1:$]WVALID ##[1:$]WREADY) |=> ##[0:$]BVALID;
	endproperty	
	
	property p8;
		@(posedge ACLK) first_match(ARVALID ##[1:$]ARREADY) |=> ##[0:$]RVALID;
	endproperty
	
	prp1 : assert property(p1)
			`uvm_info("Property Write Address Handshake","\nAwready went low after handshake",UVM_LOW)
		else
			`uvm_info("Property Write Address Handshake","\nAwready did not go low after handshake",UVM_LOW)
				
	prp2 : assert property(p2)
			`uvm_info("Property Write Data Handshake","\nwready went low after handshake",UVM_LOW)
		else	
			`uvm_info("Property Write Data Handshake","\nwready did not go low after handshake",UVM_LOW)
	
	prp3 : assert property(p3)
			`uvm_info("Property Write response Handshake","\nbready went low after handshake",UVM_LOW)
		else
			`uvm_info("Property Write response Handshake","\nbready didn't went low",UVM_LOW)

	prp4 : assert property(p4)
			`uvm_info("Property Read Address Handshake","\nArready went low after handshake",UVM_LOW)
		else
			`uvm_info("Property Read Address Handshake","\nArready didn't went low",UVM_LOW)

	prp5 : assert property(p5)
			`uvm_info("Property Read Data Handshake","\nrready went low after handshake",UVM_LOW)
		else
			`uvm_info("Property Read Data Handshake","\nrready didn't went low",UVM_LOW)


prp6 : cover property(p1); //Address channel handshake
prp7 : cover property(p2); //write data channel handshake
prp8 : cover property(p3); //write response channel handshake
prp9 : cover property(p4); //read address channel handshake
prp10 : cover property(p5); //read data/response channel handshake
prp11 : cover property(p6); //write response channel dependecy
prp12 : cover property(p7); //write response channnel dependency
prp13 : cover property(p8); //read data channel dependency
//prp6 : cover property(p1);

	
	modport m_drv_mp(clocking m_drv);
	modport m_mon_mp(clocking m_mon);
	modport s_drv_mp(clocking s_drv);
	modport s_mon_mp(clocking s_mon);

	
endinterface