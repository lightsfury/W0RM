`timescale 1ns/100ps

module W0RM_TopLevel #(
  parameter SINGLE_CYCLE  = 0,
  parameter INST_CACHE    = 0,
  parameter INST_WIDTH    = 16,
  parameter DATA_WIDTH    = 32,
  parameter ADDR_WIDTH    = 32
)(
  // Clock and reset
  input wire    core_clk,
  input wire    reset,
  
  // Instruction port
  output wire [ADDR_WIDTH-1:0]  inst_addr_o,
  output wire                   inst_valid_o,
  input wire  [INST_WIDTH-1:0]  inst_data_i,
  input wire                    inst_valid_i,
  
  // Data port
  output wire [ADDR_WIDTH-1:0]  mem_addr_o,
  output wire [DATA_WIDTH-1:0]  mem_data_o,
  output wire                   mem_read_o,
                                mem_write_o,
                                mem_valid_o,
  input wire  [DATA_WIDTH-1:0]  mem_data_i,
  input wire                    mem_valid_i
);
  localparam NUM_REGS             = 16;
  
  localparam REG_WRITE_SOURCE_ALU = 0;
  localparam REG_WRITE_SOURCE_MEM = 1;
  localparam REG_WRITE_SOURCE_B   = 2;
  
  localparam MEM_WRITE_SOURCE_RN  = 0;
  localparam MEM_WRITE_SOURCE_RD  = 1;
  localparam MEM_WRITE_SOURCE_ALU = 2;
  localparam MEM_WRITE_SOURCE_LIT = 3;
  
  localparam MEM_ADDR_SOURCE_ALU  = 0;
  localparam MEM_ADDR_SOURCE_RN   = 1;
  localparam MEM_ADDR_SOURCE_RD   = 2;
  localparam MEM_ADDR_SOURCE_LIT  = 3;
  
  localparam ALU_OP2_SOURCE_REG = 0;
  localparam ALU_OP2_SOURCE_LIT = 1;
  
  wire                    decode_ready,
                          ifetch_ready,
                          fetch_ready,
                          execute_ready;
  wire                    decode_valid;
  
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
                          decode_memory_read,
                          decode_memory_is_pop;
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
                          rfetch_memory_read,
                          rfetch_memory_is_pop;
  wire  [1:0]             rfetch_memory_data_src;
  wire  [1:0]             rfetch_memory_addr_src;
  
  wire                    rfetch_reg_write;
  wire  [1:0]             rfetch_reg_write_source;
  wire  [3:0]             rfetch_reg_write_addr;
  
  wire  [DATA_WIDTH-1:0]  alu_rd_data,
                          alu_rn_data,
                          alu_literal;
  wire                    alu_memory_write,
                          alu_memory_read,
                          alu_memory_is_pop;
  wire  [1:0]             alu_memory_data_src;
  wire  [1:0]             alu_memory_addr_src;
  
  wire                    alu_reg_write;
  wire  [1:0]             alu_reg_write_source;
  wire  [3:0]             alu_reg_write_addr;
  
  wire  [DATA_WIDTH-1:0]  rstore_alu_result;
  wire  [DATA_WIDTH-1:0]  rstore_branch_result;
  wire                    rstore_reg_write;
  wire  [1:0]             rstore_reg_write_source;
  wire  [3:0]             rstore_reg_write_addr;
  reg   [DATA_WIDTH-1:0]  rstore_reg_write_data = 0;
  wire  [DATA_WIDTH-1:0]  rstore_mem_result;
  wire                    rstore_mem_result_valid;
  
  wire  [DATA_WIDTH-1:0]  reg_pc;
  wire  [INST_WIDTH-1:0]  mem_inst_data;
  wire  [INST_WIDTH-1:0]  ifetch_inst_data;
  
  wire  [DATA_WIDTH-1:0]  alu_result;
  reg   [DATA_WIDTH-1:0]  exec_alu_data_b = 0;
  
  wire  [DATA_WIDTH-1:0]  branch_result = 0;
  
//  reg   [DATA_WIDTH-1:0]  rstore_reg_write_data = 0;
  
  reg   [ADDR_WIDTH-1:0]  mem_addr = 0;
  reg   [DATA_WIDTH-1:0]  mem_data = 0;
  
  always @(*)
  begin
    case (rstore_reg_write_source)
      REG_WRITE_SOURCE_ALU:
        rstore_reg_write_data = rstore_alu_result;
      
      REG_WRITE_SOURCE_MEM:
        rstore_reg_write_data = rstore_mem_result;
      
      REG_WRITE_SOURCE_B:
        rstore_reg_write_data = rstore_branch_result;
      
      default:
        rstore_reg_write_data = {DATA_WIDTH{1'b0}};
    endcase
  end
  
  always @(*)
  begin
    case (alu_memory_data_src)
      MEM_WRITE_SOURCE_RN:
        mem_data = alu_rn_data;
      
      MEM_WRITE_SOURCE_RD:
        mem_data = alu_rd_data;
      
      MEM_WRITE_SOURCE_ALU:
        mem_data = alu_result;
      
      MEM_WRITE_SOURCE_LIT:
        mem_data = alu_literal;
      
      default:
        mem_data = {DATA_WIDTH{1'b0}};
    endcase
  end
  
  always @(*)
  begin
    case (alu_memory_addr_src)
      MEM_ADDR_SOURCE_ALU:
        mem_addr = alu_result;
      
      MEM_ADDR_SOURCE_RN:
        mem_addr = alu_rn_data;
      
      MEM_ADDR_SOURCE_RD:
        mem_addr = alu_rd_data;
      
      MEM_ADDR_SOURCE_LIT:
        mem_addr = alu_literal;
      
      default:
        mem_addr = {ADDR_WIDTH{1'b0}};
    endcase
  end
  
  always @(*)
  begin
    case (rfetch_alu_op2_select)
      ALU_OP2_SOURCE_REG:
        exec_alu_data_b = rfetch_rn_data;
      ALU_OP2_SOURCE_LIT:
        exec_alu_data_b = rfetch_literal;
        
      default:
        exec_alu_data_b = {DATA_WIDTH{1'b0}};
    endcase
  end
  
  // Instruction fetch
  W0RM_Core_IFetch #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .ENABLE_CACHE(INST_CACHE)
  ) iFetch (
    .clk(core_clk),
    .reset(reset),
    
    .decode_ready(decode_ready),
    .ifetch_ready(ifetch_ready),
    
    // To Memory
    .reg_pc(inst_addr_o),
    .reg_pc_valid(inst_valid_o),
    
    // From Memory
    .inst_data_in(inst_data_i),
    .inst_valid_in(inst_valid_i),
    
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
    
    .fetch_ready(fetch_ready),
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
    .decode_memory_is_pop(decode_memory_is_pop),
    .decode_memory_data_src(decode_memory_data_src),
    .decode_memory_addr_src(decode_memory_addr_src),
    
    .decode_reg_write(decode_reg_write),
    .decode_reg_write_source(decode_reg_write_source),
    .decode_reg_write_addr(decode_reg_write_addr)
  );
  
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
decode_memory_is_pop // 1
decode_memory_data_src // 2
decode_memory_addr_src // 2
// 7
    
decode_reg_write // 1
decode_reg_write_source // 2
decode_reg_write_addr // 4
// 7
// */
  
  // Register file
  W0RM_Core_RegisterFile #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .NUM_USER_BITS(32 + 10 + 5 + 7 + 7 + 1)
  ) regFile (
    .clk(core_clk),
    .reset(reset),
    
    .alu_ready(execute_ready),
    .reg_file_ready(fetch_ready),
    
    .port_read0_addr(decode_rd_addr),
    .port_read0_data(rfetch_rd_data),
    
    .port_read1_addr(decode_rn_addr),
    .port_read1_data(rfetch_rn_data),
    
    .user_data_in({decode_literal, decode_alu_op2_select, decode_alu_ext_8_16,
                   decode_alu_opcode, decode_alu_store_flags, decode_is_branch,
                   decode_is_cond_branch, decode_branch_code,
                   decode_memory_write, decode_memory_read, decode_memory_is_pop,
                   decode_memory_data_src, decode_memory_addr_src,
                   decode_reg_write, decode_reg_write_source,
                   decode_reg_write_addr,
                   decode_valid}),
    .user_data_out({rfetch_literal, rfetch_alu_op2_select, rfetch_alu_ext_8_16,
                    rfetch_alu_opcode, rfetch_alu_store_flags, rfetch_is_branch,
                    rfetch_is_cond_branch, rfetch_branch_code,
                    rfetch_memory_write, rfetch_memory_read, rfetch_memory_is_pop,
                    rfetch_memory_data_src, rfetch_memory_addr_src,
                    rfetch_reg_write, rfetch_reg_write_source,
                    rfetch_reg_write_addr,
                    rfetch_valid}),
    
    .port_write_addr(rstore_reg_write_addr),
    .port_write_enable(rstore_reg_write && rstore_mem_result_valid),
    .port_write_data(rstore_reg_write_data)
  );
  
/*
rfetch_rd_data // 32
rfetch_rn_data // 32
rfetch_literal // 32
96

decode_memory_write // 1
decode_memory_read // 1
decode_memory_is_pop // 1
decode_memory_data_src // 2
decode_memory_addr_src // 2
7

decode_reg_write // 1
decode_reg_write_source // 2
decode_reg_write_addr // 4
7
*/

  // ALU
  W0RM_Core_ALU #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(96 + 7 + 7)
  ) alu (
    .clk(core_clk),
    
    .mem_ready(mem_ready),
    .alu_ready(execute_ready),
    
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
    .flag_carry(),
    
    .user_data_in({
      rfetch_rd_data,
      rfetch_rn_data,
      rfetch_literal,
      rfetch_memory_write,
      rfetch_memory_read,
      rfetch_memory_is_pop,
      rfetch_memory_data_src,
      rfetch_memory_addr_src,
      rfetch_reg_write,
      rfetch_reg_write_source,
      rfetch_reg_write_addr
    }),
    .user_data_out({
      alu_rd_data,
      alu_rn_data,
      alu_literal,
      alu_memory_write,
      alu_memory_read,
      alu_memory_is_pop,
      alu_memory_data_src,
      alu_memory_addr_src,
      
      alu_reg_write,
      alu_reg_write_source,
      alu_reg_write_addr
    })
  );
  
  // Branch unit
  W0RM_Core_Branch #(
    .SINGLE_CYCLE(SINGLE_CYCLE)
  ) branch ();

/*
  wire                    alu_reg_write; // 1
  wire  [1:0]             alu_reg_write_source; // 2
  wire  [3:0]             alu_reg_write_addr; // 4
*/
  
  // Memory interface unit
  W0RM_Core_Memory #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .USER_WIDTH(32 + 32 + 7)
  ) mem (
    .clk(core_clk),
    
    .mem_ready(mem_ready), // Not used
    
    .mem_output_valid(rstore_mem_result_valid),
    .mem_data_out(rstore_mem_result),
    
    .mem_write(alu_memory_write),
    .mem_read(alu_memory_read),
    .mem_is_pop(alu_memory_is_pop),
    .mem_addr(mem_addr),
    .mem_data(mem_data),
    .mem_valid_i(alu_result_valid),
    
    //.mem_data_src(alu_memory_data_src),
    //.mem_addr_src(alu_memory_addr_src),
    
    // Data bus port
    .data_bus_write_out(mem_write_o),
    .data_bus_read_out(mem_read_o),
    .data_bus_valid_out(mem_valid_o),
    .data_bus_addr_out(mem_addr_o),
    .data_bus_data_out(mem_data_o),
    
    .data_bus_data_in(mem_data_i),
    .data_bus_valid_in(mem_valid_i),
    
    .user_data_in({
      alu_result,
      branch_result,
      alu_reg_write,
      alu_reg_write_source,
      alu_reg_write_addr
    }),
    .user_data_out({
      rstore_alu_result,
      rstore_branch_result,
      rstore_reg_write,
      rstore_reg_write_source,
      rstore_reg_write_addr
    })
  );
endmodule
