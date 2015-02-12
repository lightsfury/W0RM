`timescale 1ns/100ps

module Decode_base_tb #(
  parameter INST_WIDTH    = 16,
  parameter DATA_WIDTH    = 32,
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = "",
  parameter FETCH_DELAY   = 3
)(
  output wire   done,
                error
);
  localparam ADDR_WIDTH     = 4;
  localparam FLAGS_WIDTH    = 4;
  localparam OPCODE_WIDTH   = 4;
  localparam FS_DATA_WIDTH  = INST_WIDTH + 1;
  localparam FC_DATA_WIDTH  = 64;
  
  reg   clk = 0;
  reg   fs_go = 0;
  wire  fetch_ready;
  wire  fs_done;
  reg   fetch_first_run = 1;
  
  wire  fs_valid;
  
  wire  [INST_WIDTH-1:0]    instruction;
  wire                      inst_valid;
  
  wire                      control_valid;
  wire  [ADDR_WIDTH-1:0]    rd_addr,
                            rn_addr;
  wire  [DATA_WIDTH-1:0]    literal;
  wire                      alu_op2_select,
                            alu_ext_8_16;
  wire  [OPCODE_WIDTH-1:0]  alu_opcode;
  wire  [3:0]               alu_store_flags;
  wire                      is_branch,
                            is_cond_branch;
  wire  [2:0]               branch_code;
  wire                      memory_write,
                            memory_read,
                            reg_write;
  wire  [1:0]               reg_write_source;
  wire  [ADDR_WIDTH-1:0]    reg_write_addr;
  
  always #2.5 clk <= ~clk;
  
  initial #56 fetch_first_run <= 0;
  
  W0RM_Static_Timer #(
    .LOAD(0),
    .LIMIT(FETCH_DELAY)
  ) fetch_ready_timer (
    .clk(clk),
    
    .start(control_valid || fetch_first_run),
    .stop(fetch_ready)
  );
  
  initial #50 fs_go <= 1'b1;
  
  FileSource #(
    .DATA_WIDTH(FS_DATA_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    .ready(fs_go && decode_ready),
    .valid(fs_valid),
    .empty(fs_done),
    .data({inst_valid, instruction})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    .valid(control_valid && fetch_ready),
    .data({rd_addr, rn_addr, literal, alu_op2_select, alu_ext_8_16,
           alu_opcode, alu_store_flags, is_branch, is_cond_branch,
           branch_code, memory_write, memory_read, reg_write,
           reg_write_source, reg_write_addr}),
    .done(done),
    .error(error)
  );
  
  W0RM_Core_Decode #(
    .SINGLE_CYCLE(0),
    .DATA_WIDTH(DATA_WIDTH),
    .INST_WIDTH(INST_WIDTH)
  ) dut (
    .clk(clk),
    
    .instruction(instruction),
    .inst_valid(inst_valid),
    
    .fetch_ready(fetch_ready),
    .decode_ready(decode_ready),
    
    .control_valid(control_valid),
    
    .decode_rd_addr(rd_addr),
    .decode_rn_addr(rn_addr),
    .decode_literal(literal),

    .decode_alu_op2_select(alu_op2_select),
    .decode_alu_ext_8_16(alu_ext_8_16),
    .decode_alu_opcode(alu_opcode),
    .decode_alu_store_flags(alu_store_flags),

    .decode_is_branch(is_branch),
    .decode_is_cond_branch(is_cond_branch),
    .decode_branch_code(branch_code),

    .decode_memory_write(memory_write),
    .decode_memory_read(memory_read),

    .decode_reg_write(reg_write),
    .decode_reg_write_source(reg_write_source),
    .decode_reg_write_addr(reg_write_addr)
  );
endmodule
