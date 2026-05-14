class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)

	uvm_tlm_analysis_fifo #(txn) m_fifo;
	uvm_tlm_analysis_fifo #(txn) s_fifo;

	txn m_txn, s_txn;
	txn wtx, rtx;

	bit result;
		
	covergroup wtx_cov with function sample(bit [31:0] data, bit[3:0]strb);
		wr_address : coverpoint wtx.awaddr {
					bins lower = {[32'd0:32'd2047]};
					bins higher = {[32'd2048:32'd4095]};
					//bins lower = {[32'h0000_0000:32'h0000_ffff]};
					//bins higher = {[32'h0001_000:32'hffff_ffff]};									 //bins middle = {[32'h0000_0100:32'h000f_0000]};
					//bins higher = {[32'h0001_0000:32'hffff_ffff]};
						}
		wr_transfer_length : coverpoint wtx.awlen {
					bins len1 = {[0:4]};
					bins len2 = {[5:10]};
					bins len3 = {[11:15]};
						}
		wr_burst_size :	coverpoint wtx.awsize {
					bins byte_size[] = {0,1,2};
						}
		wr_burst_type :	coverpoint wtx.awburst {
					bins burst[] = {0,1,2};
						}
		wdata :		coverpoint data {
					bins wdata_lower = {[32'h0000_0000:32'h7fff_ffff]};
					bins wdata_higher = {[32'h8000_0000:32'hffff_ffff]};	
					//bins wdata_lower = {[32'h0000:32'h0000_00ff]};
					//bins wdata_middle = {[32'h0000_0100:32'h000f_0000]};
					//bins wdata_higher = {[32'h000f_0001:32'hffff_ffff]};
						}
		wstrb : 	coverpoint strb{
					bins single = {1,2,4,8};
					bins double = {3,6,12};
					bins all = {15};
						}
		wr_resp :	coverpoint wtx.bresp {
					bins resp = {0};
						}

		wr_type_size_len :	cross wr_burst_type,wr_burst_size,wr_transfer_length;
	endgroup

	covergroup rtx_cov with function sample(bit [31:0] data, bit[1:0]resp);
		rd_address : coverpoint rtx.araddr {
					bins lower = {[32'd0:32'd2047]};
					bins higher = {[32'd2048:32'd4095]};
					//bins lower = {[32'h0000_0000:32'h0000_ffff]};
					//bins higher = {[32'h0001_0000:32'hffff_ffff]};		
					//bins middle = {[32'h0000_0100:32'h000f_0000]};
					//bins higher = {[32'h0001_0000:32'hffff_ffff]};
						}
		rd_transfer_length : coverpoint rtx.arlen {
					bins len1 = {[0:4]};
					bins len2 = {[5:10]};
					bins len3 = {[11:15]};
						}
		rd_burst_size :	coverpoint rtx.arsize {
					bins byte_size[] = {0,1,2};
						}
		rd_burst_type :	coverpoint rtx.arburst {
					bins burst[] = {0,1,2};
						}
		rdata :		coverpoint data {
					bins rdata_lower = {[32'h0000_0000:32'h7fff_ffff]};
					bins rdata_higher = {[32'h8000_0000:32'hffff_ffff]};	
					//bins rdata_lower = {[32'h0000:32'h0000_00ff]};
					//bins rdata_middle = {[32'h0000_0100:32'h000f_0000]};
					//bins rdata_higher = {[32'h000f_0001:32'hffff_ffff]};
						}

		rd_resp :	coverpoint resp {
					bins resp = {0};
						}

		rd_type_size_len :	cross rd_burst_type,rd_burst_size,rd_transfer_length;

	endgroup

	function new(string name = "",uvm_component parent);
		super.new(name,parent);
		m_fifo = new("m_fifo",this);
		s_fifo = new("s_fifo",this);
		wtx_cov = new();
		rtx_cov = new();
	endfunction

	extern task run_phase(uvm_phase phase);
	extern function void report_phase(uvm_phase phase);
endclass

	function void scoreboard::report_phase(uvm_phase phase);
	
		
	endfunction
	
	task scoreboard::run_phase(uvm_phase phase);
		forever begin
			m_fifo.get(m_txn);
			s_fifo.get(s_txn);
			wtx = new m_txn;
			rtx = new m_txn;
			result = m_txn.compare(s_txn);
			if(result) begin
				`uvm_info(get_type_name(),"Data Matched",UVM_LOW)
				foreach(wtx.wdata[i])
				wtx_cov.sample(wtx.wdata[i],wtx.wstrb[i]);
				foreach(rtx.rdata[i])
				rtx_cov.sample(rtx.rdata[i],rtx.rresp[i]);	
			end
			else
				`uvm_info(get_type_name(),"Data Mismatch",UVM_LOW)
				
		end
	endtask
