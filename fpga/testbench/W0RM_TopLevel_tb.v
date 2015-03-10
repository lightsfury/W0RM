`timescale 1ns/100ps

module W0RM_TopLevel_tb;
  reg clk = 0, reset = 1;
  reg inst_valid_r = 0;
  
  initial #11 reset = 0;
  
  always #2.5 clk <= ~clk;
  
  wire  [15:0]  inst_data;
  
  FileSource #(
    .DATA_WIDTH(1 + 32),
    .FILE_PATH("../testbench/data/core/IFetch/IFetch_1_tb_data.txt")
  ) inst_source (
    .clk(clk),
    
    .ready(inst_req_valid),
    .valid(inst_valid),
    .empty(),
    .data(inst_data)
  );
  
  W0RM_TopLevel #(
    .SINGLE_CYCLE(0),
    .INST_CACHE(0)
  ) dut (
    .core_clk(clk),
    .reset(reset),
    
    // Instruction port
    .inst_addr_o(), // Not used
    .inst_valid_o(inst_req_valid), // Not used
    .inst_data_i(inst_data),
    .inst_valid_i(inst_valid),
    
    // Data port
    .mem_addr_o(), // Not used
    .mem_data_o(), // Not used
    .mem_read_o(), // Not used
    .mem_write_o(), // Not used
    .mem_valid_o(), // Not used
    .mem_data_i(32'd0),
    .mem_valid_i(1'b0)
  );
endmodule
