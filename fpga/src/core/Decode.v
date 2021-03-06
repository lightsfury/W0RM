`timescale 1ns/100ps

module W0RM_Core_Decode #(
  parameter SINGLE_CYCLE  = 0,
  parameter INST_WIDTH    = 16,
  parameter ADDR_WIDTH    = 4,
  parameter DATA_WIDTH    = 32
)(
  input wire                    clk,
  
  input wire                    flush,
  
  input wire  [INST_WIDTH-1:0]  instruction,
  input wire                    inst_valid,
  input wire  [DATA_WIDTH-1:0]  inst_addr,
  
  input wire                    fetch_ready,
  output wire                   decode_ready,
  
  output wire                   control_valid,
  output wire [INST_WIDTH-1:0]  decode_inst,
  // RegFetch stage
  output wire [ADDR_WIDTH-1:0]  decode_rd_addr,
                                decode_rn_addr,
  output wire [DATA_WIDTH-1:0]  decode_literal,
  // Execute stage, alu sub-stage
  output wire [1:0]             decode_alu_op1_select,
                                decode_alu_op2_select,
  output wire [1:0]             decode_rd_forward,
                                decode_rn_forward,
  output wire                   decode_alu_ext_8_16,
  output wire [3:0]             decode_alu_opcode,
                                decode_alu_store_flags,
  // Execute stage, branch sub-stage
  output wire                   decode_is_branch,
                                decode_is_cond_branch,
                                decode_branch_rel_abs,
  output wire [2:0]             decode_branch_code,
  output wire [DATA_WIDTH-1:0]  decode_branch_base_addr,
  // Memory stage
  output wire                   decode_memory_write,
                                decode_memory_read,
                                decode_memory_is_pop,
  output wire [1:0]             decode_memory_data_src,
                                decode_memory_addr_src,
  // RegStore stage
  output wire                   decode_reg_write,
  output wire [1:0]             decode_reg_write_source,
  output wire [ADDR_WIDTH-1:0]  decode_reg_write_addr
);
  localparam INST_IDENT_HIGH  = INST_WIDTH - 1;
  localparam INST_IDENT_LOW   = INST_IDENT_HIGH - 3;
  
  // Some instructions take 3 bits to decode and others 4
  localparam INST_IDENT_NOP   = 4'b0000;
  localparam INST_IDENT_EXT   = 4'b000X;
  localparam INST_IDENT_Bcond = 4'b001X;
  localparam INST_IDENT_MOV   = 4'b010X;
  localparam INST_IDENT_LDSTR = 4'b011X;
  localparam INST_IDENT_ALU   = 4'b100X;
  localparam INST_IDENT_SHIFT = 4'b101X;
  localparam INST_IDENT_RES   = 4'b110X;
  localparam INST_IDENT_PUPO  = 4'b1110;
  localparam INST_IDENT_Bucnd = 4'b1111;
  
  localparam ALU_OPCODE_AND = 4'h0;
  localparam ALU_OPCODE_OR  = 4'h1;
  localparam ALU_OPCODE_XOR = 4'h2;
  localparam ALU_OPCODE_NOT = 4'h3;
  localparam ALU_OPCODE_NEG = 4'h4;
  localparam ALU_OPCODE_MUL = 4'h5;
  localparam ALU_OPCODE_DIV = 4'h6;
  localparam ALU_OPCODE_REM = 4'h7;
  localparam ALU_OPCODE_ADD = 4'h8;
  localparam ALU_OPCODE_SUB = 4'h9;
  localparam ALU_OPCODE_SEX = 4'ha;
  localparam ALU_OPCODE_ZEX = 4'hb;
  localparam ALU_OPCODE_LSR = 4'hc;
  localparam ALU_OPCODE_LSL = 4'hd;
  localparam ALU_OPCODE_ASR = 4'he;
  localparam ALU_OPCODE_MOV = 4'hf;
  
  localparam INST_EXT_ADDR_HIGH = 7;
  localparam INST_EXT_ADDR_LOW  = 4;
  localparam INST_EXT_ZERO_SIGN = 11;
  localparam INST_EXT_ZERO      = 1;
  localparam INST_EXT_SIGN      = 0;
  localparam INST_EXT_8_16      = 10;
  localparam INST_EXT_8         = 0;
  localparam INST_EXT_16        = 1;
  
  localparam INST_Bcond_ADDR_HIGH = 3;
  localparam INST_Bcond_ADDR_LOW  = 0;
  localparam INST_Bcond_LIT_HIGH  = 7;
  localparam INST_Bcond_LIT_LOW   = 0;
  localparam INST_Bcond_LINK      = 11;
  localparam INST_Bcond_LINK_YES  = 1;
  localparam INST_Bcond_LINK_NO   = 0;
  localparam INST_Bcond_SRC       = 12;
  localparam INST_Bcond_SRC_LIT   = 0;
  localparam INST_Bcond_SRC_REG   = 1;
  localparam INST_Bcond_CODE_HIGH = 10;
  localparam INST_Bcond_CODE_LOW  = 8;
  
  localparam INST_MOV_Rd_HIGH     = 11;
  localparam INST_MOV_Rd_LOW      = 8;
  localparam INST_MOV_Rn_HIGH     = 3;
  localparam INST_MOV_Rn_LOW      = 0;
  localparam INST_MOV_LIT_HIGH    = 7;
  localparam INST_MOV_LIT_LOW     = 0;
  localparam INST_MOV_SRC         = 12;
  localparam INST_MOV_SRC_LIT     = 1;
  localparam INST_MOV_SRC_REG     = 0;
  
  localparam INST_LDSTR_TYPE      = 12;
  localparam INST_LDSTR_TYPE_LOAD = 0;
  localparam INST_LDSTR_TYPE_STR  = 1;
  localparam INST_LDSTR_RD_HIGH   = 11;
  localparam INST_LDSTR_RD_LOW    = 8;
  localparam INST_LDSTR_RN_HIGH   = 7;
  localparam INST_LDSTR_RN_LOW    = 4;
  localparam INST_LDSTR_LIT_HIGH  = 3;
  localparam INST_LDSTR_LIT_LOW   = 0;
  
  localparam INST_ALU_RD_HIGH     = 7;
  localparam INST_ALU_RD_LOW      = 4;
  localparam INST_ALU_RN_HIGH     = 3;
  localparam INST_ALU_RN_LOW      = 0;
  localparam INST_ALU_LIT_HIGH    = 3;
  localparam INST_ALU_LIT_LOW     = 0;
  localparam INST_ALU_SRC         = 12;
  localparam INST_ALU_SRC_LIT     = 0;
  localparam INST_ALU_SRC_REG     = 1;
  localparam INST_ALU_OPCODE_HIGH = 11;
  localparam INST_ALU_OPCODE_LOW  = 8;
  
  localparam INST_SHIFT_RD_HIGH   = 11;
  localparam INST_SHIFT_RD_LOW    = 8;
  localparam INST_SHIFT_RN_HIGH   = 3;
  localparam INST_SHIFT_RN_LOW    = 0;
  localparam INST_SHIFT_LIT_HIGH  = 4;
  localparam INST_SHIFT_LIT_LOW   = 0;
  localparam INST_SHIFT_OP_HIGH   = 7;
  localparam INST_SHIFT_OP_LOW    = 6;
  localparam INST_SHIFT_SRC       = 12;
  localparam INST_SHIFT_SRC_LIT   = 0;
  localparam INST_SHIFT_SRC_REG   = 1;
  
  localparam INST_PUPO_RD_HIGH    = 3;
  localparam INST_PUPO_RD_LOW     = 0;
  localparam INST_PUPO_TYPE       = 11;
  localparam INST_PUPO_TYPE_PUSH  = 0;
  localparam INST_PUPO_TYPE_POP   = 1;
  
  localparam INST_Bucnd_RD_HIGH   = 3;
  localparam INST_Bucnd_RD_LOW    = 0;
  localparam INST_Bucnd_LIT_HIGH  = 9;
  localparam INST_Bucnd_LIT_LOW   = 0;
  localparam INST_Bucnd_SRC       = 11;
  localparam INST_Bucnd_SRC_LIT   = 0;
  localparam INST_Bucnd_SRC_REG   = 1;
  localparam INST_Bucnd_LINK      = 10;
  localparam INST_Bucnd_LINK_YES  = 1;
  localparam INST_Bucnd_LINK_NO   = 0;
  
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
  
  localparam ALU_OP1_SOURCE_RD  = 2'd0;
  localparam ALU_OP1_SOURCE_RN  = 2'd1;
  localparam ALU_OP1_SOURCE_LIT = 2'd2;
  
  localparam ALU_OP2_SOURCE_RD  = 2'd0;
  localparam ALU_OP2_SOURCE_RN  = 2'd1;
  localparam ALU_OP2_SOURCE_LIT = 2'd2;
  
  localparam ALU_REG_FWD_NONE   = 2'd0;
  localparam ALU_REG_FWD_ALU    = 2'd1;
  localparam ALU_REG_FWD_MEM    = 2'd2;
  localparam ALU_REG_FWD_RSTORE = 2'd3;
  
  localparam REG_ADDR_STACK_REG = 13;
  localparam REG_ADDR_LINK_REG  = 14;
  
  function [DATA_WIDTH-1:0] sign_extend_8(input reg[7:0] d);
    begin
      sign_extend_8 = {{24{d[7]}}, d[7:0]};
    end
  endfunction
  
  function [DATA_WIDTH-1:0] sign_extend_10(input reg[9:0] d);
    begin
      sign_extend_10 = {{22{d[9]}}, d[9:0]};
    end
  endfunction
  
  reg   bad_inst = 0;
  
  reg   [INST_WIDTH-1:0]  instruction_r = 0;
  reg                     inst_valid_r = 0;
  reg   [DATA_WIDTH-1:0]  inst_addr_r = 0;
  
  reg   [ADDR_WIDTH-1:0]  rd_addr_r = 0,
                          rn_addr_r = 0;
  reg   [DATA_WIDTH-1:0]  literal_r = 0;
  reg                     alu_ext_8_16_r = 0;
  reg   [3:0]             alu_opcode_r = 0,
                          alu_store_flags_r = 0;
  reg                     is_branch_r = 0,
                          is_cond_branch_r = 0,
                          branch_rel_abs_r = 0;
  reg   [2:0]             branch_code_r = 0;
  reg                     memory_write_r = 0,
                          memory_read_r = 0;
  reg   [1:0]             memory_data_src_r = 0,
                          memory_addr_src_r = 0;
  reg                     memory_is_pop_r = 0;
  reg                     reg_write_r = 0;
  reg   [1:0]             reg_write_source_r = 0;
  reg   [ADDR_WIDTH-1:0]  reg_write_addr_r = 0;
  reg                     alu_reg_write_r = 0,
                          mem_reg_write_r = 0,
                          rstore_reg_write_r = 0;
  reg   [ADDR_WIDTH-1:0]  alu_reg_addr_r = 0,
                          mem_reg_addr_r = 0,
                          rstore_reg_addr_r = 0;
  reg   [1:0]             alu_op1_select_i = 0,
                          alu_op2_select_i = 0;
  reg                     alu_mem_read_r = 0,
                          mem_mem_read_r = 0;
  reg   [1:0]             rd_fwd_r = 0,
                          rn_fwd_r = 0;
  reg                     stall = 0;
  
  always @(posedge clk)
  begin
    if (flush)
    begin
      instruction_r <= {INST_WIDTH{1'b0}};
      inst_addr_r   <= {DATA_WIDTH{1'b0}};
      inst_valid_r  <= 1'b0;
    end
    else if (fetch_ready)
    begin
      if (!stall)
      begin
        inst_valid_r <= 1'b0;
      
        if (inst_valid)
        begin
          instruction_r <= instruction;
          inst_addr_r   <= inst_addr;
          inst_valid_r  <= 1'b1;
        end
      end
      
      alu_reg_write_r     <= reg_write_r && ~stall;
      mem_reg_write_r     <= alu_reg_write_r;
      rstore_reg_write_r  <= mem_reg_write_r;
      
      alu_reg_addr_r      <= reg_write_addr_r;
      mem_reg_addr_r      <= alu_reg_addr_r;
      rstore_reg_addr_r   <= mem_reg_addr_r;
      
      alu_mem_read_r      <= memory_read_r && ~stall;
      mem_mem_read_r      <= alu_mem_read_r;
    end
  end
  
  assign decode_ready = fetch_ready && ~stall;
  
  always @(inst_valid_r, fetch_ready, instruction_r)
  begin
    if (inst_valid_r && fetch_ready)
    begin
      casex (instruction_r[INST_IDENT_HIGH:INST_IDENT_LOW])
        INST_IDENT_NOP:
        begin
          rd_addr_r           = 0;
          rn_addr_r           = 0;
          literal_r           = 0;
          
          alu_op1_select_i    = 0;
          alu_op2_select_i    = 0;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = 0;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r  = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = 0;
          reg_write_source_r  = 0;
          reg_write_addr_r    = 0;
          
          bad_inst            = 1;
        end
        
        INST_IDENT_EXT:
        begin
          rd_addr_r           = instruction_r[INST_EXT_ADDR_HIGH:INST_EXT_ADDR_LOW];
          rn_addr_r           = 0;
          literal_r           = 0;
          
          alu_op1_select_i    = ALU_OP1_SOURCE_RD;
          alu_op2_select_i    = ALU_OP2_SOURCE_RN;
          alu_ext_8_16_r      = instruction_r[INST_EXT_8_16];
          alu_opcode_r        = (instruction_r[INST_EXT_ZERO_SIGN] == INST_EXT_ZERO)
                                ? ALU_OPCODE_ZEX : ALU_OPCODE_SEX;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r  = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = 1;
          reg_write_source_r  = REG_WRITE_SOURCE_ALU;
          reg_write_addr_r    = instruction_r[INST_EXT_ADDR_HIGH:INST_EXT_ADDR_LOW];
          
          bad_inst            = 0;
        end
        
        INST_IDENT_Bcond:
        begin
          rd_addr_r           = 0;
          rn_addr_r           = instruction_r[INST_Bcond_ADDR_HIGH:INST_Bcond_ADDR_LOW];
          literal_r           = sign_extend_8(instruction_r[INST_Bcond_LIT_HIGH:INST_Bcond_LIT_LOW]);
          
          alu_op1_select_i    = ALU_OP1_SOURCE_RD;
          alu_op2_select_i    = (instruction_r[INST_Bcond_SRC] == INST_Bcond_SRC_REG)
                                ? ALU_OP2_SOURCE_RN : ALU_OP2_SOURCE_LIT;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = ALU_OPCODE_MOV;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 1;
          is_cond_branch_r    = 1;
          branch_code_r       = instruction_r[INST_Bcond_CODE_HIGH:INST_Bcond_CODE_LOW];
          branch_rel_abs_r    = (instruction_r[INST_Bucnd_SRC] == INST_Bucnd_SRC_REG)
                              ? 1'b1 : 1'b0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r  = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = (instruction_r[INST_Bcond_LINK] == INST_Bcond_LINK_YES);
          reg_write_source_r  = REG_WRITE_SOURCE_B;
          reg_write_addr_r    = REG_ADDR_LINK_REG;
          
          bad_inst            = 0;
        end
        
        INST_IDENT_MOV:
        begin
          rd_addr_r           = 0;
          rn_addr_r           = instruction_r[INST_MOV_Rn_HIGH:INST_MOV_Rn_LOW];
          literal_r           = {24'd0, instruction_r[INST_MOV_LIT_HIGH:INST_MOV_LIT_LOW]};
          
          alu_op1_select_i    = ALU_OP1_SOURCE_LIT;
          alu_op2_select_i    = (instruction_r[INST_MOV_SRC] == INST_MOV_SRC_REG)
                                ? ALU_OP2_SOURCE_RN : ALU_OP2_SOURCE_LIT;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = ALU_OPCODE_MOV;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r  = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = 1;
          reg_write_source_r  = REG_WRITE_SOURCE_ALU;
          reg_write_addr_r    = instruction_r[INST_MOV_Rd_HIGH:INST_MOV_Rd_LOW];
          
          bad_inst            = 0;
        end
        
        INST_IDENT_LDSTR:
        begin
          rd_addr_r           = instruction_r[INST_LDSTR_RD_HIGH:INST_LDSTR_RD_LOW];
          rn_addr_r           = instruction_r[INST_LDSTR_RN_HIGH:INST_LDSTR_RN_LOW];
          literal_r           = instruction_r[INST_LDSTR_LIT_HIGH:INST_LDSTR_LIT_LOW];
          
          alu_op1_select_i    = ALU_OP1_SOURCE_RN;
          alu_op2_select_i    = ALU_OP2_SOURCE_LIT;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = ALU_OPCODE_ADD;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = (instruction_r[INST_LDSTR_TYPE] == INST_LDSTR_TYPE_STR);
          memory_read_r       = (instruction_r[INST_LDSTR_TYPE] == INST_LDSTR_TYPE_LOAD);
          memory_data_src_r   = MEM_DATA_SRC_RD;
          memory_addr_src_r   = MEM_ADDR_SRC_ALU;
          memory_is_pop_r     = 0;
          
          reg_write_r         = (instruction_r[INST_LDSTR_TYPE] == INST_LDSTR_TYPE_LOAD);
          reg_write_source_r  = REG_WRITE_SOURCE_MEM;
          reg_write_addr_r    = instruction_r[INST_LDSTR_RD_HIGH:INST_LDSTR_RD_LOW];
          
          bad_inst            = 0;
        end
        
        INST_IDENT_ALU:
        begin
          rd_addr_r           = instruction_r[INST_ALU_RD_HIGH:INST_ALU_RD_LOW];
          rn_addr_r           = instruction_r[INST_ALU_RN_HIGH:INST_ALU_RN_LOW];
          literal_r           = instruction_r[INST_ALU_LIT_HIGH:INST_ALU_LIT_LOW];
          
          alu_op1_select_i    = ALU_OP1_SOURCE_RD;
          alu_op2_select_i    = (instruction_r[INST_ALU_SRC] == INST_ALU_SRC_REG)
                                ? ALU_OP2_SOURCE_RN : ALU_OP2_SOURCE_LIT;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = instruction_r[INST_ALU_OPCODE_HIGH:INST_ALU_OPCODE_LOW];
          alu_store_flags_r   = 4'hf;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r  = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = 1;
          reg_write_source_r  = REG_WRITE_SOURCE_ALU;
          reg_write_addr_r    = instruction_r[INST_ALU_RD_HIGH:INST_ALU_RD_LOW];
          
          bad_inst            = 0;
        end
        
        INST_IDENT_SHIFT:
        begin
          rd_addr_r           = instruction_r[INST_SHIFT_RD_HIGH:INST_SHIFT_RD_LOW];
          rn_addr_r           = instruction_r[INST_SHIFT_RN_HIGH:INST_SHIFT_RN_LOW];
          literal_r           = instruction_r[INST_SHIFT_LIT_HIGH:INST_SHIFT_LIT_LOW];
          
          alu_op1_select_i    = ALU_OP1_SOURCE_RD;
          alu_op2_select_i    = (instruction_r[INST_SHIFT_SRC] == INST_SHIFT_SRC_REG)
                                ? ALU_OP2_SOURCE_RN : ALU_OP2_SOURCE_LIT;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = ALU_OPCODE_LSR + instruction_r[INST_SHIFT_OP_HIGH:INST_SHIFT_OP_LOW];
          alu_store_flags_r   = 4'hf;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r   = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = 1;
          reg_write_source_r  = REG_WRITE_SOURCE_ALU;
          reg_write_addr_r    = instruction_r[INST_SHIFT_RD_HIGH:INST_SHIFT_RD_LOW];
          
          bad_inst            = 0;
        end
        
        INST_IDENT_RES:
        begin
          rd_addr_r           = 0;
          rn_addr_r           = 0;
          literal_r           = 0;
          
          alu_op1_select_i    = 0;
          alu_op2_select_i    = 0;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = 0;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r  = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = 0;
          reg_write_source_r  = 0;
          reg_write_addr_r    = 0;
          
          bad_inst            = 1;
        end
        
        INST_IDENT_PUPO:
        begin
          rd_addr_r           = REG_ADDR_STACK_REG;
          rn_addr_r           = instruction_r[INST_PUPO_RD_HIGH:INST_PUPO_RD_LOW];
          literal_r           = 4;
          
          alu_op1_select_i    = ALU_OP1_SOURCE_RD;
          alu_op2_select_i    = ALU_OP2_SOURCE_LIT;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = (instruction_r[INST_PUPO_TYPE] == INST_PUPO_TYPE_PUSH) ? ALU_OPCODE_SUB : ALU_OPCODE_ADD;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = (instruction_r[INST_PUPO_TYPE] == INST_PUPO_TYPE_PUSH);
          memory_read_r       = (instruction_r[INST_PUPO_TYPE] == INST_PUPO_TYPE_POP);
          memory_data_src_r  = 0;
          memory_addr_src_r   = (instruction_r[INST_PUPO_TYPE] == INST_PUPO_TYPE_PUSH) ? MEM_ADDR_SRC_ALU : MEM_ADDR_SRC_RN;
          memory_is_pop_r     = (instruction_r[INST_PUPO_TYPE] == INST_PUPO_TYPE_POP);
          
          reg_write_r         = (instruction_r[INST_PUPO_TYPE] == INST_PUPO_TYPE_POP);
          reg_write_source_r  = REG_WRITE_SOURCE_MEM;
          reg_write_addr_r    = instruction_r[INST_PUPO_RD_HIGH:INST_PUPO_RD_LOW];
          
          bad_inst            = 0;
        end
        
        INST_IDENT_Bucnd:
        begin
          rd_addr_r           = 0;
          rn_addr_r           = instruction_r[INST_Bucnd_RD_HIGH:INST_Bucnd_RD_LOW];
          literal_r           = sign_extend_10(instruction_r[INST_Bucnd_LIT_HIGH:INST_Bucnd_LIT_LOW]);
          
          alu_op1_select_i    = ALU_OP1_SOURCE_LIT;
          alu_op2_select_i    = (instruction_r[INST_Bucnd_SRC] == INST_Bucnd_SRC_REG)
                              ? ALU_OP2_SOURCE_RN : ALU_OP2_SOURCE_LIT;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = 0;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 1;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = (instruction_r[INST_Bucnd_SRC] == INST_Bucnd_SRC_REG)
                              ? 1'b1 : 1'b0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r   = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = (instruction_r[INST_Bucnd_LINK] == INST_Bucnd_LINK_YES);
          reg_write_source_r  = REG_WRITE_SOURCE_B;
          reg_write_addr_r    = REG_ADDR_LINK_REG;
          
          bad_inst            = 0;
        end
        
        default:
        begin
          rd_addr_r           = 0;
          rn_addr_r           = 0;
          literal_r           = 0;
          
          alu_op1_select_i    = 0;
          alu_op2_select_i    = 0;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = 0;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r  = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = 0;
          reg_write_source_r  = 0;
          reg_write_addr_r    = 0;
          
          bad_inst            = 1;
        end
      endcase
    end
    else
    begin
          rd_addr_r           = 0;
          rn_addr_r           = 0;
          literal_r           = 0;
          
          alu_op1_select_i    = 0;
          alu_op2_select_i    = 0;
          alu_ext_8_16_r      = 0;
          alu_opcode_r        = 0;
          alu_store_flags_r   = 0;
          
          is_branch_r         = 0;
          is_cond_branch_r    = 0;
          branch_code_r       = 0;
          branch_rel_abs_r    = 0;
          
          memory_write_r      = 0;
          memory_read_r       = 0;
          memory_data_src_r  = 0;
          memory_addr_src_r   = 0;
          memory_is_pop_r     = 0;
          
          reg_write_r         = 0;
          reg_write_source_r  = 0;
          reg_write_addr_r    = 0;
          
          bad_inst            = 0;
    end
  end
  
  always @(alu_reg_write_r, mem_reg_write_r, rstore_reg_write_r,
           rstore_reg_addr_r, mem_reg_addr_r, alu_reg_addr_r,
           rd_addr_r, rn_addr_r, mem_mem_read_r, alu_mem_read_r)
  begin
    if (alu_reg_write_r || mem_reg_write_r || rstore_reg_write_r)
    begin
      rd_fwd_r = ALU_REG_FWD_NONE;
      rn_fwd_r = ALU_REG_FWD_NONE;
      stall    = 0;
  
      if (rstore_reg_write_r && (rstore_reg_addr_r == rd_addr_r))
      begin
        rd_fwd_r  = ALU_REG_FWD_RSTORE;
      end
  
      if (rstore_reg_write_r && (rstore_reg_addr_r == rn_addr_r))
      begin
        rn_fwd_r  = ALU_REG_FWD_RSTORE;
      end
      
      if (mem_reg_write_r && (mem_reg_addr_r == rd_addr_r))
      begin
        rd_fwd_r  = ALU_REG_FWD_MEM;
        stall     = mem_mem_read_r;
      end
  
      if (mem_reg_write_r && (mem_reg_addr_r == rn_addr_r))
      begin
        rn_fwd_r  = ALU_REG_FWD_MEM;
        stall     = mem_mem_read_r;
      end
      
      if (alu_reg_write_r && (alu_reg_addr_r == rd_addr_r))
      begin
        rd_fwd_r  = ALU_REG_FWD_ALU;
        stall     = alu_mem_read_r;
      end
      
      if (alu_reg_write_r && (alu_reg_addr_r == rn_addr_r))
      begin
        rn_fwd_r  = ALU_REG_FWD_ALU;
        stall     = alu_mem_read_r;
      end
    end
    else
    begin
      rd_fwd_r  = ALU_REG_FWD_NONE;
      rn_fwd_r  = ALU_REG_FWD_NONE;
      stall     = 0;
    end
  end
  
  assign control_valid           = inst_valid_r && ~bad_inst && ~stall;
  
  assign decode_rd_addr          = rd_addr_r;
  assign decode_rn_addr          = rn_addr_r;
  assign decode_literal          = literal_r;
  
  assign decode_rd_forward       = rd_fwd_r;
  assign decode_rn_forward       = rn_fwd_r;
  
  assign decode_alu_op1_select   = alu_op1_select_i;
  assign decode_alu_op2_select   = alu_op2_select_i;
  assign decode_alu_ext_8_16     = alu_ext_8_16_r;
  assign decode_alu_opcode       = alu_opcode_r;
  assign decode_alu_store_flags  = alu_store_flags_r;
  
  assign decode_is_branch        = is_branch_r;
  assign decode_is_cond_branch   = is_cond_branch_r;
  assign decode_branch_rel_abs   = branch_rel_abs_r;
  assign decode_branch_code      = branch_code_r;
  assign decode_branch_base_addr = inst_addr_r;
  
  assign decode_memory_write     = memory_write_r;
  assign decode_memory_read      = memory_read_r;
  assign decode_memory_is_pop    = memory_is_pop_r;
  assign decode_memory_data_src  = memory_data_src_r;
  assign decode_memory_addr_src  = memory_addr_src_r;
  
  assign decode_reg_write        = reg_write_r;
  assign decode_reg_write_source = reg_write_source_r;
  assign decode_reg_write_addr   = reg_write_addr_r;
  assign decode_inst             = instruction_r;
endmodule