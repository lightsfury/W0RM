`timescale 1ns/100ps

module W0RM_ALU_Shifts #(
  parameter SINGLE_CYCLE  = 0,
  parameter DATA_WIDTH    = 8
)(
  input wire                    clk,
  
  input wire                    data_valid,
  input wire  [3:0]             opcode,
  
  input wire  [DATA_WIDTH-1:0]  data_a,
                                data_b,
  
  output wire [DATA_WIDTH-1:0]  result,
  output wire                   result_valid,
  output wire [3:0]             result_flags
);
  
  localparam ALU_OPCODE_AND = 4'h0;
  localparam ALU_OPCODE_OR  = 4'h1;
  localparam ALU_OPCODE_XOR = 4'h2;
  localparam ALU_OPCODE_NOT = 4'h3;
  localparam ALU_OPCODE_NEG = 4'h4;

endmodule
