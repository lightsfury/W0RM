`timescale 1ns/100ps

module IFetch_base_tb #(
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire done,
              error
);
  localparam INST_WIDTH = 16;
  localparam FS_DATA_WIDTH  = INST_WIDTH + 1;
  localparam FC_DATA_WIDTH  = INST_WIDTH;
  
  reg clk = 0;
  reg reset = 1;
  
  always #2.5 clk <= ~clk;
  
  initial #11 reset = 0;
  
  wire          inst_valid_in;
  wire  [15:0]  inst_data_in;
  
  wire          inst_valid_out;
  wire  [15:0]  inst_data_out;
  
  wire          inst_addr_valid;
  wire  [31:0]  inst_addr;
  
  FileSource #(
    .DATA_WIDTH(FS_DATA_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    .ready(fs_go),
    .valid(fs_valid),
    .empty(fs_done),
    .data({inst_valid_in, inst_data_in})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    .valid(inst_valid_out),
    .data(inst_data_out),
    .done(done),
    .error(error)
  );
  
  W0RM_Core_IFetch #(
    .SINGLE_CYCLE(1),
    .ENABLE_CACHE(0)
  ) dut (
    .clk(clk),
    .reset(reset),
    
    .decode_ready(1'b1),
    .ifetch_ready(fs_go),
    
    .reg_pc(inst_addr),
    .reg_pc_valid(inst_addr_valid),
    
    .inst_data_in(inst_data_in),
    .inst_valid_in(inst_valid_in && fs_valid),
    
    .inst_data_out(inst_data_out),
    .inst_valid_out(inst_valid_out)
  );
endmodule
