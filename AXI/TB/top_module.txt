module top;

	import uvm_pkg::*;	
	import test_pkg::*;
	
	bit ACLK;
	
	initial begin
		forever #5 ACLK = ~ACLK;
	end	

	AXI intrf(ACLK);
	
	initial begin
		uvm_config_db #(virtual AXI) :: set(null,"*","Interface",intrf);

		`ifdef VCS
		$fsdbDumpvars(0,top);
		`endif
		run_test();
	end
endmodule