`timescale 1ns/100ps

module W0RM_Core_Branch #(
  parameter SINGLE_CYCLE  = 0,
  parameter USER_WIDTH    = 0,
  parameter DATA_WIDTH    = 32,
  parameter ADDR_WIDTH    = 32
)(
  input wire                    clk,
  
  input wire                    mem_ready,
  output wire                   branch_ready,
  
  input wire                    data_valid,
  input wire                    is_branch,
  input wire                    is_cond_branch,
  input wire  [2:0]             cond_branch_code,
  
  input wire                    alu_flag_zero,
                                alu_flag_negative,
                                alu_flag_carry,
                                alu_flag_overflow,
  
  input wire  [ADDR_WIDTH-1:0]  branch_base_addr,
  input wire                    branch_rel_abs,
  
  input wire  [DATA_WIDTH-1:0]  rn,
                                lit,
  
  output wire                   branch_valid,
  output wire                   flush_pipeline,
  output wire [ADDR_WIDTH-1:0]  next_pc,
  output wire [DATA_WIDTH-1:0]  next_link_reg,
  output wire                   next_pc_valid,
  
  input wire  [USER_WIDTH-1:0]  user_data_in,
  output wire [USER_WIDTH-1:0]  user_data_out
);
  localparam BRANCH_IS_ABSOLUTE = 1;
  localparam BRANCH_IS_RELATIVE = 0;
  
  localparam BRANCH_COND_CODE_ZERO_SET    = 0;
  localparam BRANCH_COND_CODE_ZERO_CLEAR  = 1;
  localparam BRANCH_COND_CODE_CARRY_SET   = 2;
  localparam BRANCH_COND_CODE_CARRY_CLEAR = 3;
  localparam BRANCH_COND_CODE_OVER_SET    = 4;
  localparam BRANCH_COND_CODE_OVER_CLEAR  = 5;
  localparam BRANCH_COND_CODE_NEG_SET     = 6;
  localparam BRANCH_COND_CODE_NEG_CLEAR   = 7;
  
  reg                     data_valid_r = 0;
  reg                     is_branch_r = 0;
  reg                     is_cond_branch_r = 0;
  reg   [2:0]             cond_branch_code_r = 0;
  reg   [ADDR_WIDTH-1:0]  base_addr_r = 0;
  reg                     is_rel_abs_r = 0;
  reg   [DATA_WIDTH-1:0]  rn_r = 0,
                          lit_r = 0;
  reg                     branch_valid_r = 0;
  reg   [ADDR_WIDTH-1:0]  next_pc_r = 0;
  reg                     next_pc_valid_r = 0;
  reg   [DATA_WIDTH-1:0]  next_link_reg_r = 0;
  
  reg   [USER_WIDTH-1:0]  user_data_r = 0,
                          user_data_r2 = 0;
  
  reg                     branch_busy_r = 0;
  reg                     branch_taken = 0;
  reg                     next_pc_valid_i = 0;
  reg   [ADDR_WIDTH-1:0]  next_pc_i;
  reg                     alu_flag_zero_r = 0,
                          alu_flag_carry_r = 0,
                          alu_flag_overflow_r = 0,
                          alu_flag_negative_r = 0;
  
  assign branch_ready   = mem_ready; // && ~branch_busy_r;
  assign branch_valid   = branch_valid_r;
  assign flush_pipeline = next_pc_valid_r;
  assign next_pc_valid  = next_pc_valid_r;
  assign next_pc        = next_pc_r;
  assign next_link_reg  = next_link_reg_r;
  assign user_data_out  = user_data_r2;
  
  always @(is_branch_r, is_cond_branch_r, cond_branch_code_r)
  begin
    if (is_branch_r)
    begin
      if (is_cond_branch_r)
      begin
        case (cond_branch_code_r)
          BRANCH_COND_CODE_ZERO_SET:
            branch_taken = alu_flag_zero_r == 1;
          
          BRANCH_COND_CODE_ZERO_CLEAR:
            branch_taken = alu_flag_zero_r == 0;
            
          BRANCH_COND_CODE_CARRY_SET:
            branch_taken = alu_flag_carry_r == 1;
          
          BRANCH_COND_CODE_CARRY_CLEAR:
            branch_taken = alu_flag_carry_r == 0;
            
          BRANCH_COND_CODE_OVER_SET:
            branch_taken = alu_flag_overflow_r == 1;
          
          BRANCH_COND_CODE_OVER_CLEAR:
            branch_taken = alu_flag_overflow_r == 0;
            
          BRANCH_COND_CODE_NEG_SET:
            branch_taken = alu_flag_negative_r == 1;
          
          BRANCH_COND_CODE_NEG_CLEAR:
            branch_taken = alu_flag_negative_r == 0;
          
          default:
            branch_taken = 1'b0;
        endcase
      end
      else
      begin
        branch_taken = 1'b1;
      end
    end
    else
    begin
      branch_taken = 1'b0;
    end
  end
  
  always @(branch_taken, is_rel_abs_r, base_addr_r, lit_r, rn_r)
  begin
    if (branch_taken)
    begin
      next_pc_valid_i = 1;
      if (is_rel_abs_r == BRANCH_IS_RELATIVE)
      begin
        next_pc_i = base_addr_r + lit_r + 2;
      end
      else // Absolute address
      begin
        next_pc_i = rn_r;
      end
    end
    else
    begin
      next_pc_i       = 0;
      next_pc_valid_i = 0;
    end
  end
  
  always @(posedge clk)
  begin
    if (flush_pipeline)
    begin
      next_pc_r           <= 0;
      next_pc_valid_r     <= 0;
      branch_valid_r      <= 0;
      //branch_busy_r       <= 0;
      is_branch_r         <= 0;
      is_cond_branch_r    <= 0;
      cond_branch_code_r  <= 0;
      base_addr_r         <= 0;
      is_rel_abs_r        <= 0;
      rn_r                <= 0;
      lit_r               <= 0;
      alu_flag_zero_r     <= 0;
      alu_flag_carry_r    <= 0;
      alu_flag_overflow_r <= 0;
      alu_flag_negative_r <= 0;
      user_data_r         <= {USER_WIDTH{1'b0}};
      user_data_r2        <= {USER_WIDTH{1'b0}};
    end
    else
    begin
      if (data_valid && is_branch && mem_ready)
      begin
        is_branch_r         <= is_branch;
        is_cond_branch_r    <= is_cond_branch;
        cond_branch_code_r  <= cond_branch_code;
        base_addr_r         <= branch_base_addr;
        is_rel_abs_r        <= branch_rel_abs;
        rn_r                <= rn;
        lit_r               <= lit;
        alu_flag_zero_r     <= alu_flag_zero;
        alu_flag_carry_r    <= alu_flag_carry;
        alu_flag_overflow_r <= alu_flag_overflow;
        alu_flag_negative_r <= alu_flag_negative;
        //branch_busy_r       <= 1'b1;
        
        user_data_r         <= user_data_in;
      end
      
      if (data_valid_r && mem_ready)
      begin
        next_pc_r       <= next_pc_i;
        next_pc_valid_r <= next_pc_valid_i;
      
        if (branch_taken)
        begin
          next_link_reg_r <= base_addr_r + 2;
          user_data_r2    <= user_data_r;
        end
        else
        begin
          next_link_reg_r <= {DATA_WIDTH{1'b0}};
          user_data_r2    <= {USER_WIDTH{1'b0}};
        end
        
        if (~(data_valid && is_branch && mem_ready))
        begin
          is_branch_r         <= 1'b0;
          is_cond_branch_r    <= 1'b0;
          cond_branch_code_r  <= 3'd0;
          base_addr_r         <= {DATA_WIDTH{1'b0}};
          is_rel_abs_r        <= 1'b0;
          rn_r                <= {DATA_WIDTH{1'b0}};
          lit_r               <= {DATA_WIDTH{1'b0}};
          alu_flag_zero_r     <= 1'b0;
          alu_flag_carry_r    <= 1'b0;
          alu_flag_overflow_r <= 1'b0;
          alu_flag_negative_r <= 1'b0;
          //branch_busy_r       <= 1'b0;
        end
      end
      
      data_valid_r    <= data_valid && mem_ready;
      branch_valid_r  <= data_valid_r && branch_taken;
    end
  end
endmodule