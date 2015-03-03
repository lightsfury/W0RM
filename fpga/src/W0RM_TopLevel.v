`timescale 1ns/100ps

module W0RM_TopLevel #(
  parameter SINGLE_CYCLE  = 0,
  parameter INST_CACHE    = 0
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
  localparam INST_WIDTH = 16;
  localparam DATA_WIDTH = 32;
  localparam NUM_REGS   = 16;
  
  wire core_clk = BaseCLK;
  
  wire                    decode_ready,
                          ifetch_ready,
                          execute_ready;
  wire                    decode_valid;

  //wire  [INST_WIDTH-1:0]  instruction;
  //wire                    inst_valid;
  
  wire  [3:0]             decode_rd_addr,
                          decode_rn_addr;
  wire  [DATA_WIDTH-1:0]  decode_literal;
  
  wire                    decode_alu_op2_select,
                          decode_alu_ext_8_16;
  wire  [3:0]             decode_alu_opcode;
  wire  [3:0]             decode_alu_store_flags;
  
  wire                    decode_is_branch,
                          decode_is_cond_branch;
  wire  [2:0]             decode_branch_code;
  
  wire                    decode_memory_write,
                          decode_memory_read;
  wire  [1:0]             decode_memory_data_src;
  wire  [1:0]             decode_memory_addr_src;
  
  wire                    decode_reg_write;
  wire  [1:0]             decode_reg_write_source;
  wire  [3:0]             decode_reg_write_addr;
  
  wire  [DATA_WIDTH-1:0]  rfetch_rd_data,
                          rfetch_rn_data;
  wire  [DATA_WIDTH-1:0]  rfetch_literal;
  
  wire                    rfetch_alu_op2_select,
                          rfetch_alu_ext_8_16;
  wire  [3:0]             rfetch_alu_opcode;
  wire  [3:0]             rfetch_alu_store_flags;
  
  wire                    rfetch_is_branch,
                          rfetch_is_cond_branch;
  wire  [2:0]             rfetch_branch_code;
  
  wire                    rfetch_memory_write,
                          rfetch_memory_read;
  wire  [1:0]             rfetch_memory_data_src;
  wire  [1:0]             rfetch_memory_addr_src;
  
  wire                    rfetch_reg_write;
  wire  [1:0]             rfetch_reg_write_source;
  wire  [3:0]             rfetch_reg_write_addr;
  
  wire  [DATA_WIDTH-1:0]  reg_pc;
  wire  [INST_WIDTH-1:0]  mem_inst_data;
  wire  [INST_WIDTH-1:0]  ifetch_inst_data;
  
  wire  [DATA_WIDTH-1:0]  alu_result;
  wire  [DATA_WIDTH-1:0]  exec_alu_data_b;
  
  // Instruction fetch
  W0RM_Core_IFetch #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .ENABLE_CACHE(INST_CACHE)
  ) iFetch (
    .clk(core_clk),
    .reset(Reset),
    
    .decode_ready(decode_ready),
    .ifetch_ready(ifetch_ready),
    
    // To Memory
    .reg_pc(reg_pc),
    .reg_pc_valid(reg_pc_valid),
    
    // From Memory
    .inst_data_in(mem_inst_data),
    .inst_valid_in(inst_valid_out),
    
    // To Decode
    .inst_data_out(ifetch_inst_data),
    .inst_valid_out(ifetch_inst_valid)
  );
  
  // Decode
  W0RM_Core_Decode #(
    .SINGLE_CYCLE(SINGLE_CYCLE)
  ) decode (
    .clk(core_clk),
    
    .instruction(ifetch_inst_data),
    .inst_valid(ifetch_inst_valid),
    
    .fetch_ready(execute_ready),
    .decode_ready(decode_ready),
    
    .control_valid(decode_valid),
    
    .decode_rd_addr(decode_rd_addr),
    .decode_rn_addr(decode_rn_addr),
    .decode_literal(decode_literal),
    
    .decode_alu_op2_select(decode_alu_op2_select),
    .decode_alu_ext_8_16(decode_alu_ext_8_16),
    .decode_alu_opcode(decode_alu_opcode),
    .decode_alu_store_flags(decode_alu_store_flags),
    
    .decode_is_branch(decode_is_branch),
    .decode_is_cond_branch(decode_is_cond_branch),
    .decode_branch_code(decode_branch_code),
    
    .decode_memory_write(decode_memory_write),
    .decode_memory_read(decode_memory_read),
    .decode_memory_data_src(decode_memory_data_src),
    .decode_memory_addr_src(decode_memory_addr_src),
    
    .decode_reg_write(decode_reg_write),
    .decode_reg_write_source(decode_reg_write_source),
    .decode_reg_write_addr(decode_reg_write_addr)
  );
  
  // ALU
  W0RM_Core_ALU #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH)
  ) alu (
    .clk(core_clk),
    
    .ready(execute_ready),
    
    .opcode(rfetch_alu_opcode),
    .data_valid(rfetch_valid),
    .store_flags_mask(rfetch_alu_store_flags),
    .ext_bit_size(rfetch_alu_ext_8_16),
    
    .data_a(rfetch_rd_data),
    .data_b(exec_alu_data_b),
    
    .result(alu_result),
    .result_valid(alu_result_valid),
    
    .flag_zero(),
    .flag_negative(),
    .flag_overflow(),
    .flag_carry()
  );
  
  // Branch unit
  W0RM_Core_Branch #(
    .SINGLE_CYCLE(SINGLE_CYCLE)
  ) branch ();
  
  // Bus unit
  W0RM_Core_Bus #(
    .SINGLE_CYCLE(SINGLE_CYCLE)
  ) busUnit ();
  
/*
decode_rd_addr  // 4
decode_rn_addr  // 4
decode_literal // 32
// 40
    
decode_alu_op2_select // 1
decode_alu_ext_8_16 // 1
decode_alu_opcode // 4
decode_alu_store_flags // 4
// 10
    
decode_is_branch  // 1
decode_is_cond_branch // 1
decode_branch_code // 3
// 5
    
decode_memory_write // 1
decode_memory_read // 1
decode_memory_data_src // 2
decode_memory_addr_src // 2
// 6
    
decode_reg_write // 1
decode_reg_write_source // 2
decode_reg_write_addr // 4
// 7
// */
  
  // Register file
  W0RM_Core_RegisterFile #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .NUM_USER_BITS(32 + 10 + 5 + 6 + 7 + 1)
  ) regFile (
    .clk(core_clk),
    .reset(Reset),
    
    .port_read0_addr(decode_rd_addr),
    .port_read0_data(rfetch_rd_data),
    
    .port_read1_addr(decode_rn_addr),
    .port_read1_data(rfetch_rn_data),
    
    .user_data_in({decode_literal, decode_alu_op2_select, decode_alu_ext_8_16,
                   decode_alu_opcode, decode_alu_store_flags, decode_is_branch,
                   decode_is_cond_branch, decode_branch_code,
                   decode_memory_write, decode_memory_read,
                   decode_memory_data_src, decode_memory_addr_src,
                   decode_reg_write, decode_reg_write_source,
                   decode_reg_write_addr,
                   decode_valid}),
    .user_data_out({rfetch_literal, rfetch_alu_op2_select, rfetch_alu_ext_8_16,
                    rfetch_alu_opcode, rfetch_alu_store_flags, rfetch_is_branch,
                    rfetch_is_cond_branch, rfetch_branch_code,
                    rfetch_memory_write, rfetch_memory_read,
                    rfetch_memory_data_src, rfetch_memory_addr_src,
                    rfetch_reg_write, rfetch_reg_write_source,
                    rfetch_reg_write_addr,
                    rfetch_valid}),
    
    .port_write_addr(4'h0),
    .port_write_enable(1'b0),
    .port_write_data(32'h0)
    
  );
  
  W0RM_CoreMemory #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .BLOCK_RAM(1)
  ) memory (
    .clk(core_clk),
    
    .inst_addr(reg_pc),
    .inst_read(reg_pc_valid),
    .inst_valid_in(ifetch_ready),
    .inst_data_out(mem_inst_data),
    .inst_valid_out(inst_valid_out),
    
    .bus_addr(),
    .bus_read(),
    .bus_write(),
    .bus_valid_in(),
    .bus_data_in(),
    .bus_data_out(),
    .bus_valid_out()
  );
endmodule
