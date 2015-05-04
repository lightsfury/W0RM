`timescale 1ns/100ps

module W0RM_TopLevel #(
  parameter SINGLE_CYCLE  = 1,
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
  input wire  [ADDR_WIDTH-1:0]  inst_addr_i,
  
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
  
  localparam REG_WRITE_SOURCE_ALU = 2'd0;
  localparam REG_WRITE_SOURCE_MEM = 2'd1;
  localparam REG_WRITE_SOURCE_B   = 2'd2;
  
  localparam MEM_DATA_SRC_RN      = 2'd0;
  localparam MEM_DATA_SRC_RD      = 2'd1;
  localparam MEM_DATA_SRC_ALU     = 2'd2;
  localparam MEM_DATA_SRC_LIT     = 2'd3;
  
  localparam MEM_ADDR_SRC_RN      = 2'd0;
  localparam MEM_ADDR_SRC_RD      = 2'd1;
  localparam MEM_ADDR_SRC_ALU     = 2'd2;
  localparam MEM_ADDR_SRC_LIT     = 2'd3;
  
  localparam ALU_OP1_SOURCE_RD    = 2'd0;
  localparam ALU_OP1_SOURCE_RN    = 2'd1;
  localparam ALU_OP1_SOURCE_LIT   = 2'd2;
  
  localparam ALU_OP2_SOURCE_RD    = 2'd0;
  localparam ALU_OP2_SOURCE_RN    = 2'd1;
  localparam ALU_OP2_SOURCE_LIT   = 2'd2;
  
  localparam ALU_REG_FWD_NONE     = 2'd0;
  localparam ALU_REG_FWD_ALU      = 2'd1;
  localparam ALU_REG_FWD_MEM      = 2'd2;
  localparam ALU_REG_FWD_RSTORE   = 2'd3;
  
  wire                    decode_ready,
                          ifetch_ready,
                          fetch_ready,
                          execute_ready,
                          branch_ready,
                          alu_ready;
  wire                    decode_valid;
  
  wire  [INST_WIDTH-1:0]  decode_inst,
                          rfetch_inst,
                          alu_inst,
                          branch_inst,
                          rstore_inst;
  
  wire  [3:0]             decode_rd_addr,
                          decode_rn_addr;
  wire  [DATA_WIDTH-1:0]  decode_literal;
  
  wire                    decode_alu_ext_8_16;
  wire  [1:0]             decode_alu_op1_select,
                          decode_alu_op2_select;
  wire  [3:0]             decode_alu_opcode;
  wire  [3:0]             decode_alu_store_flags;
  
  wire                    decode_is_branch,
                          decode_is_cond_branch;
  wire  [2:0]             decode_branch_code;
  wire  [DATA_WIDTH-1:0]  decode_branch_base_addr;
  
  wire                    decode_memory_write,
                          decode_memory_read,
                          decode_memory_is_pop;
  wire  [1:0]             decode_memory_data_src,
                          decode_memory_addr_src;
  wire  [1:0]             decode_rd_forward,
                          decode_rn_forward;
  
  wire                    decode_reg_write;
  wire  [1:0]             decode_reg_write_source;
  wire  [3:0]             decode_reg_write_addr;
  
  wire  [DATA_WIDTH-1:0]  rfetch_rd_data,
                          rfetch_rn_data;
  wire  [DATA_WIDTH-1:0]  rfetch_literal;
  
  wire                    rfetch_alu_ext_8_16;
  wire  [1:0]             rfetch_alu_op1_select,
                          rfetch_alu_op2_select;
  wire  [3:0]             rfetch_alu_opcode;
  wire  [3:0]             rfetch_alu_store_flags;
  
  wire                    rfetch_is_branch,
                          rfetch_is_cond_branch;
  wire  [2:0]             rfetch_branch_code;
  wire  [DATA_WIDTH-1:0]  rfetch_branch_base_addr;
  
  wire                    rfetch_memory_write,
                          rfetch_memory_read,
                          rfetch_memory_is_pop;
  wire  [1:0]             rfetch_memory_data_src,
                          rfetch_memory_addr_src;
  
  wire                    rfetch_reg_write;
  wire  [1:0]             rfetch_reg_write_source;
  wire  [3:0]             rfetch_reg_write_addr;
  wire  [1:0]             rfetch_rd_forward,
                          rfetch_rn_forward;
  reg   [DATA_WIDTH-1:0]  exec_rd_data,
                          exec_rn_data;
  
  wire  [DATA_WIDTH-1:0]  alu_rd_data,
                          alu_rn_data,
                          alu_literal;
  wire                    alu_memory_write,
                          alu_memory_read,
                          alu_memory_is_pop;
  wire  [1:0]             alu_memory_data_src,
                          alu_memory_addr_src;
  
  wire                    alu_reg_write;
  wire  [1:0]             alu_reg_write_source;
  wire  [3:0]             alu_reg_write_addr;
  
  wire  [DATA_WIDTH-1:0]  branch_rd_data,
                          branch_rn_data,
                          branch_literal;
  wire                    branch_memory_write,
                          branch_memory_read,
                          branch_memory_is_pop;
  wire  [1:0]             branch_memory_data_src,
                          branch_memory_addr_src;
  
  wire                    branch_reg_write;
  wire  [1:0]             branch_reg_write_source;
  wire  [3:0]             branch_reg_write_addr;
  
  wire  [DATA_WIDTH-1:0]  rstore_alu_result;
  wire  [DATA_WIDTH-1:0]  rstore_branch_result;
  wire                    rstore_reg_write;
  wire  [1:0]             rstore_reg_write_source;
  wire  [3:0]             rstore_reg_write_addr;
  reg   [DATA_WIDTH-1:0]  rstore_reg_write_data = 0;
  wire  [DATA_WIDTH-1:0]  rstore_mem_result;
  wire                    rstore_mem_result_valid;
  
  reg   [1:0]             mem_addr_src = 0,
                          mem_data_src = 0;
  reg   [DATA_WIDTH-1:0]  mem_rd_data = 0,
                          mem_rn_data = 0,
                          mem_literal = 0;
  
  //wire  [DATA_WIDTH-1:0]  reg_pc;
  //wire  [INST_WIDTH-1:0]  mem_inst_data;
  wire  [INST_WIDTH-1:0]  ifetch_inst_data;
  wire  [ADDR_WIDTH-1:0]  ifetch_inst_addr;
  
  wire  [DATA_WIDTH-1:0]  branch_next_pc;
  wire                    branch_flush_pipeline,
                          branch_next_pc_valid;
  
  wire  [DATA_WIDTH-1:0]  alu_result,
                          alu_result_forward;
  reg   [DATA_WIDTH-1:0]  exec_alu_data_a = 0,
                          exec_alu_data_b = 0;
  reg   [DATA_WIDTH-1:0]  alu_result_r = 0;
  wire  [DATA_WIDTH-1:0]  alu_result_i;
  
  wire  [DATA_WIDTH-1:0]  branch_result;
  
  reg   [ADDR_WIDTH-1:0]  mem_addr = 0;
  reg   [DATA_WIDTH-1:0]  mem_data = 0;
  reg   [DATA_WIDTH-1:0]  rstore_reg_write_data_r = 0;
  wire                    alu_result_valid;
  
  assign alu_result_i = alu_result_valid ? alu_result : alu_result_r;
  
  //*
  always @(posedge core_clk)
    if (alu_result_valid)
      alu_result_r <= alu_result_forward;
  // */
  
  always @(posedge core_clk)
    if (rstore_reg_write && rstore_mem_result_valid)
      rstore_reg_write_data_r <= rstore_reg_write_data;
  
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
    case (mem_data_src)
      MEM_DATA_SRC_RN:
        mem_data = mem_rn_data;
      
      MEM_DATA_SRC_RD:
        mem_data = mem_rd_data;
      
      MEM_DATA_SRC_ALU:
        mem_data = alu_result;
      
      MEM_DATA_SRC_LIT:
        mem_data = mem_literal;
      default:
        mem_data = {DATA_WIDTH{1'b0}};
    endcase
  end
  
  always @(*)
  begin
    case (mem_addr_src)
      MEM_ADDR_SRC_ALU:
        mem_addr = alu_result;
      
      MEM_ADDR_SRC_RN:
        mem_addr = mem_rn_data;
      
      MEM_ADDR_SRC_RD:
        mem_addr = mem_rd_data;
      
      MEM_ADDR_SRC_LIT:
        mem_addr = mem_literal;
      
      default:
        mem_addr = {ADDR_WIDTH{1'b0}};
    endcase
  end
  
  always @(*)
  begin
    case (rfetch_rd_forward)
      ALU_REG_FWD_NONE:
        exec_rd_data  = rfetch_rd_data;
      
      ALU_REG_FWD_ALU:
        exec_rd_data  = alu_result_i;
      
      ALU_REG_FWD_MEM:
        exec_rd_data  = rstore_reg_write_data;
      
      ALU_REG_FWD_RSTORE:
        exec_rd_data  = rstore_reg_write_data_r;
    endcase
  end
  
  always @(*)
  begin
    case (rfetch_rn_forward)
      ALU_REG_FWD_NONE:
        exec_rn_data  = rfetch_rn_data;
      
      ALU_REG_FWD_ALU:
        exec_rn_data  = alu_result_i;
      
      ALU_REG_FWD_MEM:
        exec_rn_data  = rstore_reg_write_data;
      
      ALU_REG_FWD_RSTORE:
        exec_rn_data  = rstore_reg_write_data_r;
    endcase
  end
  
  always @(*)
  begin
    case (rfetch_alu_op1_select)
      ALU_OP1_SOURCE_RD:
        exec_alu_data_a = exec_rd_data;
      
      ALU_OP1_SOURCE_RN:
        exec_alu_data_a = exec_rn_data;
      
      ALU_OP1_SOURCE_LIT:
        exec_alu_data_a = rfetch_literal;
      
      default:
        exec_alu_data_a = {DATA_WIDTH{1'b0}};
    endcase
  end
  
  always @(*)
  begin
    case (rfetch_alu_op2_select)
      ALU_OP2_SOURCE_RD:
        exec_alu_data_b = exec_rd_data;
      
      ALU_OP2_SOURCE_RN:
        exec_alu_data_b = exec_rn_data;
      
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
    
    .branch_data_valid(branch_valid),
    .branch_flush(branch_flush_pipeline),
    .next_pc(branch_next_pc),
    .next_pc_valid(branch_next_pc_valid),
    
    .decode_ready(decode_ready),
    .ifetch_ready(ifetch_ready),
    
    // To Memory
    .reg_pc(inst_addr_o),
    .reg_pc_valid(inst_valid_o),
    
    // From Memory
    .inst_data_in(inst_data_i),
    .inst_valid_in(inst_valid_i),
    .inst_addr_in(inst_addr_i),
    
    // To Decode
    .inst_data_out(ifetch_inst_data),
    .inst_valid_out(ifetch_inst_valid),
    .inst_addr_out(ifetch_inst_addr)
  );
  
  // Decode
  W0RM_Core_Decode #(
    .SINGLE_CYCLE(SINGLE_CYCLE)
  ) decode (
    .clk(core_clk),
    
    .flush(branch_flush_pipeline && branch_valid),
    
    .instruction(ifetch_inst_data),
    .inst_valid(ifetch_inst_valid),
    .inst_addr(ifetch_inst_addr),
    
    .fetch_ready(fetch_ready),
    .decode_ready(decode_ready),
    
    .control_valid(decode_valid),
    .decode_inst(decode_inst),
    
    .decode_rd_addr(decode_rd_addr),
    .decode_rn_addr(decode_rn_addr),
    .decode_literal(decode_literal),
    
    .decode_alu_op1_select(decode_alu_op1_select),
    .decode_alu_op2_select(decode_alu_op2_select),
    .decode_rd_forward(decode_rd_forward),
    .decode_rn_forward(decode_rn_forward),
    .decode_alu_ext_8_16(decode_alu_ext_8_16),
    .decode_alu_opcode(decode_alu_opcode),
    .decode_alu_store_flags(decode_alu_store_flags),
    
    .decode_is_branch(decode_is_branch),
    .decode_is_cond_branch(decode_is_cond_branch),
    .decode_branch_rel_abs(decode_branch_rel_abs),
    .decode_branch_code(decode_branch_code),
    .decode_branch_base_addr(decode_branch_base_addr),
    
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


decode_rd_forward // 2
decode_rn_forward // 2
decode_alu_op1_select // 2
decode_alu_op2_select // 2
decode_alu_ext_8_16 // 1
decode_alu_opcode // 4
decode_alu_store_flags // 4
// 17
    
decode_is_branch  // 1
decode_is_cond_branch // 1
decode_branch_rel_abs // 1
decode_branch_code // 3
decode_branch_base_addr // 32
// 38
    
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
  
  assign execute_ready  = alu_ready && branch_ready;
  
  // Register file
  W0RM_Core_RegisterFile #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .USER_WIDTH(32 + 17 + 38 + 7 + 7 + 16)
  ) regFile (
    .clk(core_clk),
    .reset(reset),
    
    .flush(branch_flush_pipeline && branch_valid),
    
    .decode_valid(decode_valid),
    .rfetch_valid(rfetch_valid),
    
    .alu_ready(execute_ready),
    .reg_file_ready(fetch_ready),
    
    .port_read0_addr(decode_rd_addr),
    .port_read0_data(rfetch_rd_data),
    
    .port_read1_addr(decode_rn_addr),
    .port_read1_data(rfetch_rn_data),
    
    .user_data_in({decode_literal, decode_alu_op1_select, decode_alu_op2_select,
                   decode_alu_ext_8_16, decode_alu_opcode,
                   decode_alu_store_flags, decode_is_branch,
                   decode_is_cond_branch, decode_branch_code,
                   decode_branch_base_addr, decode_branch_rel_abs,
                   decode_memory_write, decode_memory_read,
                   decode_memory_is_pop, decode_memory_data_src,
                   decode_memory_addr_src, decode_reg_write,
                   decode_reg_write_source, decode_reg_write_addr,
                   decode_rd_forward, decode_rn_forward, decode_inst}),
    .user_data_out({rfetch_literal, rfetch_alu_op1_select, rfetch_alu_op2_select,
                    rfetch_alu_ext_8_16, rfetch_alu_opcode,
                    rfetch_alu_store_flags, rfetch_is_branch,
                    rfetch_is_cond_branch, rfetch_branch_code,
                    rfetch_branch_base_addr, rfetch_branch_rel_abs,
                    rfetch_memory_write, rfetch_memory_read,
                    rfetch_memory_is_pop, rfetch_memory_data_src,
                    rfetch_memory_addr_src, rfetch_reg_write,
                    rfetch_reg_write_source, rfetch_reg_write_addr,
                    rfetch_rd_forward, rfetch_rn_forward, rfetch_inst}),
    
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
    .USER_WIDTH(96 + 7 + 7 + 16)
  ) alu (
    .clk(core_clk),
    
    .flush(branch_flush_pipeline && branch_valid),
    
    .mem_ready(mem_ready),
    .alu_ready(alu_ready),
    
    .opcode(rfetch_alu_opcode),
    .data_valid(rfetch_valid),
    .store_flags_mask(rfetch_alu_store_flags),
    .ext_bit_size(rfetch_alu_ext_8_16),
    
    .data_a(exec_alu_data_a),
    .data_b(exec_alu_data_b),
    
    .result(alu_result),
    .result_forward(alu_result_forward),
    .result_valid(alu_result_valid),
    
    .flag_zero(alu_flag_zero),
    .flag_negative(alu_flag_negative),
    .flag_overflow(alu_flag_overflow),
    .flag_carry(alu_flag_carry),
    .result_flags_forward({alu_flag_carry_forward, alu_flag_overflow_forward,
                           alu_flag_negative_forward, alu_flag_zero_forward}),
    
    .user_data_in({
      exec_rd_data,
      exec_rn_data,
      rfetch_literal,
      rfetch_memory_write,
      rfetch_memory_read,
      rfetch_memory_is_pop,
      rfetch_memory_data_src,
      rfetch_memory_addr_src,
      rfetch_reg_write,
      rfetch_reg_write_source,
      rfetch_reg_write_addr,
      rfetch_inst
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
      alu_reg_write_addr,
      alu_inst
    })
  );
  
  // Branch unit
  W0RM_Core_Branch #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .USER_WIDTH(96 + 7 + 7 + 16)
  ) branch (
    .clk(core_clk),
    
    .mem_ready(mem_ready),
    .branch_ready(branch_ready),
    
    .data_valid(rfetch_valid && rfetch_is_branch),
    .is_branch(rfetch_is_branch),
    .is_cond_branch(rfetch_is_cond_branch),
    .cond_branch_code(rfetch_branch_code),
    
    //.alu_flags(result_flags_forward),
    
    /*
    .alu_flag_zero(alu_flag_zero_forward),
    .alu_flag_negative(alu_flag_negative_forward),
    .alu_flag_carry(alu_flag_carry_forward),
    .alu_flag_overflow(alu_flag_overflow_forward),
    // */
    
    .alu_flag_zero(alu_flag_zero),
    .alu_flag_negative(alu_flag_negative),
    .alu_flag_carry(alu_flag_carry),
    .alu_flag_overflow(alu_flag_overflow),
    
    .branch_base_addr(rfetch_branch_base_addr),
    .branch_rel_abs(rfetch_branch_rel_abs),
    
    .rn(exec_rn_data),
    .lit(rfetch_literal),
    
    .branch_valid(branch_valid),
    .flush_pipeline(branch_flush_pipeline),
    .next_pc(branch_next_pc),
    .next_link_reg(branch_result),
    .next_pc_valid(branch_next_pc_valid),
    
    .user_data_in({
      exec_rd_data,
      exec_rn_data,
      rfetch_literal,
      rfetch_memory_write,
      rfetch_memory_read,
      rfetch_memory_is_pop,
      rfetch_memory_data_src,
      rfetch_memory_addr_src,
      
      rfetch_reg_write,
      rfetch_reg_write_source,
      rfetch_reg_write_addr,
      rfetch_inst
    }),
    .user_data_out({
      branch_rd_data,
      branch_rn_data,
      branch_literal,
      branch_memory_write,
      branch_memory_read,
      branch_memory_is_pop,
      branch_memory_data_src,
      branch_memory_addr_src,
      
      branch_reg_write,
      branch_reg_write_source,
      branch_reg_write_addr,
      branch_inst
    })
  );

/*
  wire                    alu_reg_write; // 1
  wire  [1:0]             alu_reg_write_source; // 2
  wire  [3:0]             alu_reg_write_addr; // 4
*/
  localparam MEM_USER_DATA_SIZE = 32 + 32 + 7 + 16;
  reg   [MEM_USER_DATA_SIZE-1:0]  mem_user_data_in = 0;
  reg                             memory_write,
                                  memory_read,
                                  memory_is_pop;
  
  always @(*)
  begin
    if (branch_valid)
    begin
      memory_write  = branch_memory_write;
      memory_read   = branch_memory_read;
      memory_is_pop = branch_memory_is_pop;
      mem_addr_src  = branch_memory_addr_src;
      mem_data_src  = branch_memory_data_src;
      //memory_addr   = branch_mem_addr;
      //memory_data   = branch_mem_data;
      mem_rd_data   = branch_rd_data;
      //mem_rn_data   = branch_rn_data;
      mem_literal   = branch_literal;
      mem_user_data_in = {
        alu_result,
        branch_result,
        branch_reg_write,
        branch_reg_write_source,
        branch_reg_write_addr,
        branch_inst
      };
    end
    else if (alu_result_valid)
    begin
      memory_write  = alu_memory_write;
      memory_read   = alu_memory_read;
      memory_is_pop = alu_memory_is_pop;
      mem_addr_src  = alu_memory_addr_src;
      mem_data_src  = alu_memory_data_src;
      //memory_addr   = alu_memory_addr;
      //memory_data   = alu_memory_data;
      mem_rd_data   = alu_rd_data;
      //mem_rn_data   = alu_rn_data;
      mem_literal   = alu_literal;
      mem_user_data_in = {
        alu_result,
        branch_result,
        alu_reg_write,
        alu_reg_write_source,
        alu_reg_write_addr,
        alu_inst
      };
    end
    else
    begin
      memory_write  = 0;
      memory_read   = 0;
      memory_is_pop = 0;
      mem_addr_src  = 0;
      mem_data_src  = 0;
      mem_rd_data   = 0;
      mem_rn_data   = 0;
      mem_literal   = 0;
      mem_user_data_in = {MEM_USER_DATA_SIZE{1'b0}};
    end
  end
  
  // Memory interface unit
  W0RM_Core_Memory #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .USER_WIDTH(MEM_USER_DATA_SIZE)
  ) mem (
    .clk(core_clk),
    
    .mem_ready(mem_ready), // Not used
    
    .mem_output_valid(rstore_mem_result_valid),
    .mem_data_out(rstore_mem_result),
    
    .mem_write(memory_write),
    .mem_read(memory_read),
    .mem_is_pop(memory_is_pop),
    .mem_addr(mem_addr),
    .mem_data(mem_data),
    .mem_valid_i(alu_result_valid || branch_valid),
    
    // Data bus port
    .data_bus_write_out(mem_write_o),
    .data_bus_read_out(mem_read_o),
    .data_bus_valid_out(mem_valid_o),
    .data_bus_addr_out(mem_addr_o),
    .data_bus_data_out(mem_data_o),
    
    .data_bus_data_in(mem_data_i),
    .data_bus_valid_in(mem_valid_i),
    
    .user_data_in(mem_user_data_in),
    /*
    .user_data_in({
      alu_result,
      branch_result,
      alu_reg_write,
      alu_reg_write_source,
      alu_reg_write_addr
    }), // */
    .user_data_out({
      rstore_alu_result,
      rstore_branch_result,
      rstore_reg_write,
      rstore_reg_write_source,
      rstore_reg_write_addr,
      rstore_inst
    })
  );
endmodule
