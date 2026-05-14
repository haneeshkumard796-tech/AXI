class txn extends uvm_sequence_item;
	`uvm_object_utils(txn)

	//Write Address
	rand bit [3:0]awid;
	rand bit [31:0]awaddr;
	rand bit [3:0]awlen;
	rand bit [2:0]awsize;
	rand bit [1:0]awburst;
	bit awvalid;
	bit awready;
	
	//Write Data
	rand bit [3:0]wid;
	rand bit [31:0]wdata[];
	rand bit [3:0]wstrb[];
	bit wlast;
	bit wvalid;
	bit wready;

	//Write Response
	rand bit [3:0]bid;
	bit [1:0]bresp;
	bit bvalid;
	bit bready;

	//Read Address
	rand bit [3:0]arid;
	rand bit [31:0]araddr;
	rand bit [3:0]arlen;
	rand bit [2:0]arsize;
	rand bit [1:0]arburst;
	bit arvalid;
	bit arready;

	//Read Data
	rand bit [3:0]rid;
	rand bit [31:0]rdata[];
	rand bit [1:0]rresp[];
	bit rlast;
	bit rvalid;
	bit rready;

	int no_of_byte;
	int lower_byte_lane[];
	int upper_byte_lane[];
	int aligned_addr;
	int start_addr;
	bit [31:0]addr[];

	constraint c1{wdata.size()==(awlen+1);}

	constraint c2{rdata.size()==(arlen+1);}

	constraint c3{awburst dist {0:=10, 1:=10, 2:=10};}

	constraint c4{arburst dist {0:=10, 1:=10, 2:=10};}

	constraint c5{awid==wid; bid==wid;}
	
	constraint c6{rid==arid;}

	constraint c7{awsize dist {0:=10, 1:=10, 2:=10};}

	constraint c8{arsize dist {0:=10, 1:=10, 2:=10};}

	constraint c9{if(awburst==2) (awlen+1) inside {2, 4, 8, 16};}

	constraint c10{if(arburst==2) (arlen+1) inside {2, 4, 8, 16};}

	constraint c11{((awburst==2 || awburst==0) && awsize==1) -> awaddr%2==0;}

	constraint c12{((awburst==2 || awburst==0) && awsize==2) -> awaddr%4==0;}

	constraint c13{((arburst==2 || arburst==0) && arsize==1) -> araddr%2==0;}

	constraint c14{((arburst==2 || arburst==0) && arsize==1) -> araddr%4==0;}

	constraint c15{wstrb.size() == (awlen+1); rresp.size() == (arlen+1);}

	constraint c16{awaddr inside {[0:4095]}; araddr inside {[0:4095]};}

	constraint c17{foreach(rdata[i])rdata[i] dist {[32'h0000_0000:32'h7fff_ffff]:=5,[32'h8000_0000:32'hffff_ffff]:=5};}
	
	function new(string name="txn");
		super.new(name);
	endfunction
	
	function void do_print(uvm_printer printer);
		super.do_print(printer);
		
		printer.print_field("AWID",this.awid,4,UVM_DEC);
		printer.print_field("AWADDR",this.awaddr,32,UVM_DEC);
		printer.print_field("AWLEN",this.awlen,4,UVM_DEC);
		printer.print_field("AWSIZE",this.awsize,3,UVM_DEC);
		printer.print_field("AWBURST",this.awburst,2,UVM_DEC);
		printer.print_field("WID",this.wid,4,UVM_DEC);
		
		foreach(this.wdata[i]) begin
		printer.print_field($sformatf("WDATA[%0d]",i),this.wdata[i],32,UVM_HEX);
		printer.print_field($sformatf("WSTRB[%0d]",i),this.wstrb[i],4,UVM_BIN);
		end
		printer.print_field("BID",this.bid,4,UVM_DEC);
		printer.print_field("BRESP",this.bresp,2,UVM_DEC);
		printer.print_field("ARID",this.arid,4,UVM_DEC);
		printer.print_field("ARADDR",this.araddr,32,UVM_DEC);
		printer.print_field("ARLEN",this.arlen,4,UVM_DEC);
		printer.print_field("ARSIZE",this.arsize,3,UVM_DEC);
		printer.print_field("ARBURST",this.arburst,2,UVM_DEC);
		printer.print_field("RID",this.rid,4,UVM_DEC);
		
		foreach(this.rdata[i]) begin
		printer.print_field($sformatf("RDATA[%0d]",i),this.rdata[i],32,UVM_HEX);
		printer.print_field($sformatf("RRESP[%0d]",i),this.rresp[i],2,UVM_DEC);
		end

	endfunction

	function bit do_compare(uvm_object rhs,uvm_comparer comparer);
		txn rhs_;
		
		if(!$cast(rhs_,rhs))
			`uvm_fatal(get_type_name(),"Casting Failed")
		else begin
			return this.awid == rhs_.awid &&
				this.awaddr == rhs_.awaddr &&
				this.awlen == rhs_.awlen &&
				this.awsize == rhs_.awsize &&
				this.awburst == rhs_.awburst &&

				this.wid == rhs_.wid &&
				this.wdata == rhs_.wdata &&
				this.wstrb == rhs_.wstrb &&
				
				this.bid == rhs_.bid &&
				this.bresp == rhs_.bresp &&
	

				this.arid == rhs_.arid &&
				this.araddr == rhs_.araddr &&
				this.arlen == rhs_.arlen &&
				this.arsize == rhs_.arsize &&
				this.arburst == rhs_.arburst &&
				
				this.rid == rhs_.rid &&
				this.rdata == rhs_.rdata &&
				this.rresp == rhs_.rresp;
		end
	endfunction

	function void post_randomize();
		no_of_byte=2**awsize;
		aligned_addr=(int'(awaddr/no_of_byte)*no_of_byte);
		start_addr=awaddr;
		wstrb=new[awlen+1];

		cal_waddr();
		cal_strb();
		cal_raddr();	
	endfunction


	function void cal_waddr();
		bit wb;
		int burst_len=awlen+1;
		int wrap_boundary=(int'(awaddr/(no_of_byte*burst_len))*(no_of_byte*burst_len));
		int last_addr=wrap_boundary+(no_of_byte*burst_len);
		addr=new[awlen+1];
		addr[0]=awaddr;

		for(int i=2; i<burst_len+1; i++)
			begin
				if(awburst==2'b00)
					addr[i-1] = awaddr;
				else if(awburst==1)
					addr[i-1] = aligned_addr + (i-1)*no_of_byte;
				else if(awburst==2)
					begin
						if(wb==0)
							begin
								addr[i-1]=aligned_addr+(i-1)*no_of_byte;
								if(addr[i-1]==(wrap_boundary+(no_of_byte*burst_len)))
									begin
										addr[i-1]=wrap_boundary;
										wb++;
									end
							end
						else
							addr[i-1]=start_addr + ((i-1)*no_of_byte)-(no_of_byte * burst_len);
					end
			end
	endfunction




	function void cal_raddr();
		bit wb;
		int burst_len=arlen+1;
		int wrap_boundary=(int'(araddr/(no_of_byte*burst_len))*(no_of_byte*burst_len));
		int last_addr=wrap_boundary+(no_of_byte*burst_len);
		addr=new[arlen+1];
		addr[0]=awaddr;

		for(int i=2; i<burst_len+1; i++)
			begin
				if(arburst==2'b00)
					addr[i-1] = awaddr;
				else if(arburst==1)
					addr[i-1] = aligned_addr + (i-1)*no_of_byte;
				else if(arburst==2)
					begin
						if(wb==0)
							begin
								addr[i-1]=aligned_addr+(i-1)*no_of_byte;
								if(addr[i-1]==(wrap_boundary+(no_of_byte*burst_len)))
									begin
										addr[i-1]=wrap_boundary;
										wb++;
									end
							end
						else
							addr[i-1]=start_addr + ((i-1)*no_of_byte)-(no_of_byte * burst_len);
					end
			end
	endfunction

	function void cal_strb();
		wstrb=new[awlen+1];
		lower_byte_lane = new[awlen+1];
		upper_byte_lane = new[awlen+1];
				
	
		foreach(lower_byte_lane[i]) begin
			if(i==0 || awburst == 2'd0) begin
				lower_byte_lane[i] = start_addr - (int'(start_addr/4))*4;
				upper_byte_lane[i] = aligned_addr + (no_of_byte-1)-(int'(start_addr/4))*4;	
			end
			else begin
				lower_byte_lane[i] = addr[i] - (int'(addr[i]/4))*4;
				upper_byte_lane[i] = lower_byte_lane[i] + no_of_byte - 1;
			end
		end

		foreach(wstrb[j]) begin
			for(int i=0;i<4;i++) begin	
				if((i < lower_byte_lane[j]) || (i > upper_byte_lane[j]))
					wstrb[j][i] = 1'b0;	
				else
					wstrb[j][i] = 1'b1;
			end
		end
	endfunction
endclass

