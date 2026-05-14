package test_pkg;
	
	import uvm_pkg::*;
	
	`include "uvm_macros.svh"
	
	`include "txn.sv"
	`include "master_agent_config.sv"
	`include "master_sequencer.sv"
	`include "master_driver.sv"
	`include "master_monitor.sv"
	`include "master_agent.sv"
	`include "master_agent_top.sv"

	`include "slave_agent_config.sv"
	`include "slave_sequencer.sv"
	`include "slave_driver.sv"
	`include "slave_monitor.sv"
	`include "slave_agent.sv"
	`include "slave_agent_top.sv"

	`include "env_config.sv"
	`include "sb.sv"
	`include "env.sv"
	
	`include "master_sequence.sv"
	`include "test.sv"
endpackage