class master_agent_config extends uvm_object;
  2         `uvm_object_utils(master_agent_config)
  3 
  4         int no_of_agents = 1;
  5 
  6         virtual AXI intrf;
  7 
  8         function new(string name = "master_agent_config");
  9                 super.new(name);
 10         endfunction
 11 endclass