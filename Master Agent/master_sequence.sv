class master_sequence extends uvm_sequence #(txn);
	`uvm_object_utils(master_sequence)

	function new(string name="master_sequence");
		super.new(name);
	endfunction

endclass

class fixed_seq	extends master_sequence;
	`uvm_object_utils(fixed_seq)
	function new(string name="fixed_seq");
		super.new(name);
	endfunction
	

	extern task body();
endclass 

	task fixed_seq::body();
		repeat(30) begin
			req = txn::type_id::create("req");
			start_item(req);
			req.randomize() with {awburst == 2'b00; arburst == 2'b00;};
			finish_item(req);
		end
	endtask

class incr_seq	extends master_sequence;
	`uvm_object_utils(incr_seq)
	function new(string name="incr_seq");
		super.new(name);
	endfunction
	

	extern task body();
endclass 

	task incr_seq::body();
		repeat(30) begin
			req = txn::type_id::create("req");
			start_item(req);
			req.randomize() with {awburst == 2'b01; arburst == 2'b01;};
			finish_item(req);
		end
	endtask

class wrap_seq	extends master_sequence;
	`uvm_object_utils(wrap_seq)
	function new(string name="wrap_seq");
		super.new(name);
	endfunction
	

	extern task body();
endclass 

	task wrap_seq::body();
		repeat(30) begin
			req = txn::type_id::create("req");
			start_item(req);
			req.randomize() with {awburst == 2'b10; arburst == 2'b10;};
			finish_item(req);
		end
	endtask