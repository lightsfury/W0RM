`timescale 1ns/100ps

module W0RM_TopLevel #(
  parameter SINGLE_CYCLE = 0
)(
  // Clock and reset
  input wire    BaseCLK,
  input wire    Reset,
  
  // Bus interface
  output wire [31:0]  Address_o,
  output wire [31:0]  Data_o,
  output wire         Read_o,
  output wire         Write_o,
  output wire         Valid_o,
  input wire  [31:0]  Data_i,
  input wire          Valid_i
);

  // Instruction fetch
  W0RM_Core_IFetch iFetch();
  
  // Decode
  W0RM_Core_Decode decode();
  
  // Control
  W0RM_Core_Control control();
  
  // ALU
  W0RM_Core_ALU alu();
  
  // Branch unit
  W0RM_Core_Branch branch();
  
  // Bus unit
  W0RM_Core_Bus busUnit();
  
  // Register file
  W0RM_Core_RegisterFile regFile();


endmodule
