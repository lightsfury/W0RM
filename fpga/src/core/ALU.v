`timescale 1ns/100ps

module W0RM_Core_ALU #(
  parameter SINGLE_CYCLE  = 0,
  parameter DATA_WIDTH    = 8,
  parameter USER_WIDTH    = 1
)(
  input wire                    clk,
  // Operation port
  input wire  [3:0]             opcode,
  input wire                    flush,
  // Control port
  input wire                    mem_ready,
  output wire                   alu_ready,
  input wire                    data_valid,
  input wire  [3:0]             store_flags_mask,
  input wire                    ext_bit_size, // 1 for 16-bit, 0 for 8-bit
  // Data in port
  input wire  [DATA_WIDTH-1:0]  data_a,
                                data_b,
  // Data out port
  output wire [DATA_WIDTH-1:0]  result,
  output wire                   result_valid,
  output wire                   flag_zero,
                                flag_negative,
                                flag_overflow,
                                flag_carry,
  input wire  [USER_WIDTH-1:0]  user_data_in,
  output wire [USER_WIDTH-1:0]  user_data_out
);
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
  
  localparam ALU_FLAG_ZERO  = 4'h0;
  localparam ALU_FLAG_NEG   = 4'h1;
  localparam ALU_FLAG_OVER  = 4'h2;
  localparam ALU_FLAG_CARRY = 4'h3;
  
  reg   [3:0]             opcode_r = 0;
  reg   [DATA_WIDTH-1:0]  data_a_r = 0,
                          data_b_r = 0,
                          result_r = 0;
  reg                     data_valid_r = 0,
                          result_valid_r = 0,
                          pending_op = 0;
  reg   [3:0]             result_flags_r = 0,
                          store_flags_mask_r = 0;
  
  wire  [DATA_WIDTH-1:0]  result_logic,
                          result_mul,
                          result_div_rem,
                          result_add_sub,
                          result_shifts,
                          result_ext;
  wire                    result_valid_logic,
                          result_valid_mul,
                          result_valid_div_rem,
                          result_valid_add_sub,
                          result_valid_shifts,
                          result_valid_ext;
  wire  [3:0]             result_flags_logic,
                          result_flags_mul,
                          result_flags_div_rem,
                          result_flags_add_sub,
                          result_flags_shifts,
                          result_flags_ext;
  
  reg   [DATA_WIDTH-1:0]  result_i = 0;
  reg                     result_valid_i = 0;
  reg   [3:0]             result_flags_i = 0;
  
  reg   ce_logic    = 0,
        ce_mul      = 0,
        ce_div_rem  = 0,
        ce_add_sub  = 0,
        ce_shifts   = 0,
        ce_ext      = 0;
  
  reg   [USER_WIDTH-1:0]  user_data_r = 0,
                          user_data_r2 = 0;
  reg                     single_cycle = 0;
  reg                     long_opcode = 0;
  reg                     ext_bit_size_r = 0;
  
  //assign result         = result_r;
  //assign result_valid   = result_valid_r;
  assign #0.1 result         = result_i;
  assign #0.1 result_valid   = result_valid_i && data_valid_r;
  assign #0.1 flag_zero      = result_flags_r[ALU_FLAG_ZERO];
  assign #0.1 flag_negative  = result_flags_r[ALU_FLAG_NEG];
  assign #0.1 flag_overflow  = result_flags_r[ALU_FLAG_OVER];
  assign #0.1 flag_carry     = result_flags_r[ALU_FLAG_CARRY];
  //assign alu_ready      = ~pending_op || (pending_op && single_cycle && mem_ready);
  assign alu_ready      = mem_ready && (~long_opcode || result_valid_i);
  assign user_data_out  = user_data_r;
  
  always @(posedge clk)
  begin
    if (flush)
    begin
      opcode_r    <= 4'd0;
      data_a_r    <= {DATA_WIDTH{1'b0}};
      data_b_r    <= {DATA_WIDTH{1'b0}};
      user_data_r <= {USER_WIDTH{1'b0}};
    end
    else
    begin
      if (data_valid && (~data_valid_r || ~long_opcode || result_valid_i))
      begin
        data_valid_r        <= 1'b1;
        opcode_r            <= opcode;
        store_flags_mask_r  <= store_flags_mask;
        ext_bit_size_r      <= ext_bit_size;
        data_a_r            <= data_a;
        data_b_r            <= data_b;
        
        user_data_r <= user_data_in;
      end
      
      if (data_valid_r && result_valid_i)
      begin
        data_valid_r    <= data_valid;
        result_r        <= result_i;
        result_valid_r  <= result_valid_i;
        
        if (store_flags_mask_r[0])
        begin
          result_flags_r[0] <= result_flags_i[0];
        end
        
        if (store_flags_mask_r[1])
        begin
          result_flags_r[1] <= result_flags_i[1];
        end
        
        if (store_flags_mask_r[2])
        begin
          result_flags_r[2] <= result_flags_i[2];
        end
        
        if (store_flags_mask_r[3])
        begin
          result_flags_r[3] <= result_flags_i[3];
        end
        
      end
    end
  end
  
  /*
  always @(posedge clk)
  begin
    data_valid_r <= data_valid;
    
    if (flush)
    begin
      data_valid_r  <= 1'b0;
      pending_op    <= 1'b0;
      opcode_r      <= 0;
      data_a_r      <= {DATA_WIDTH{1'b0}};
      data_b_r      <= {DATA_WIDTH{1'b0}};
      user_data_r   <= {USER_WIDTH{1'b0}};
    end
    else
    begin
      if (data_valid && ~pending_op)
      begin
        opcode_r    <= opcode;
        data_a_r    <= data_a;
        data_b_r    <= data_b;
        pending_op  <= 1'b1;
        user_data_r <= user_data_in;
      end
      
      if ((single_cycle || result_valid_i) && pending_op)
      begin
        pending_op <= 1'b0;
        
        result_r  <= result_i;
        
        user_data_r2 <= user_data_r;
        
        if (store_flags_mask[0])
        begin
          result_flags_r[0] <= result_flags_i[0];
        end
        
        if (store_flags_mask[1])
        begin
          result_flags_r[1] <= result_flags_i[1];
        end
        
        if (store_flags_mask[2])
        begin
          result_flags_r[2] <= result_flags_i[2];
        end
        
        if (store_flags_mask[3])
        begin
          result_flags_r[3] <= result_flags_i[3];
        end
      end
      
      result_valid_r <= result_valid_i;
    end
  end // */
  
  always @(*)
  begin
    if (data_valid_r)
    begin
      case (opcode_r)
        ALU_OPCODE_AND:
        begin
          ce_logic    <= 1'b1;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_logic;
          result_valid_i  <= result_valid_logic;
          result_flags_i  <= result_flags_logic;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_OR:
        begin
          ce_logic    <= 1'b1;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_logic;
          result_valid_i  <= result_valid_logic;
          result_flags_i  <= result_flags_logic;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_XOR:
        begin
          ce_logic    <= 1'b1;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_logic;
          result_valid_i  <= result_valid_logic;
          result_flags_i  <= result_flags_logic;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_NOT:
        begin
          ce_logic    <= 1'b1;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_logic;
          result_valid_i  <= result_valid_logic;
          result_flags_i  <= result_flags_logic;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_NEG:
        begin
          ce_logic    <= 1'b1;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_logic;
          result_valid_i  <= result_valid_logic;
          result_flags_i  <= result_flags_logic;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_MUL:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b1;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_mul;
          result_valid_i  <= result_valid_mul;
          result_flags_i  <= result_flags_mul;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b1;
        end
        
        ALU_OPCODE_DIV:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b1;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_div_rem;
          result_valid_i  <= result_valid_div_rem;
          result_flags_i  <= result_flags_div_rem;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b1;
        end
        
        ALU_OPCODE_REM:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b1;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_div_rem;
          result_valid_i  <= result_valid_div_rem;
          result_flags_i  <= result_flags_div_rem;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b1;
        end
        
        ALU_OPCODE_ADD:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b1;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_add_sub;
          result_valid_i  <= result_valid_add_sub;
          result_flags_i  <= result_flags_add_sub;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_SUB:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b1;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= result_add_sub;
          result_valid_i  <= result_valid_add_sub;
          result_flags_i  <= result_flags_add_sub;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_SEX:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b1;
          
          result_i        <= result_ext;
          result_valid_i  <= result_valid_ext;
          result_flags_i  <= result_flags_ext;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_ZEX:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b1;
          
          result_i        <= result_ext;
          result_valid_i  <= result_valid_ext;
          result_flags_i  <= result_flags_ext;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_LSR:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b1;
          ce_ext      <= 1'b0;
          
          result_i        <= result_shifts;
          result_valid_i  <= result_valid_shifts;
          result_flags_i  <= result_flags_shifts;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_LSL:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b1;
          ce_ext      <= 1'b0;
          
          result_i        <= result_shifts;
          result_valid_i  <= result_valid_shifts;
          result_flags_i  <= result_flags_shifts;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_ASR:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b1;
          ce_ext      <= 1'b0;
          
          result_i        <= result_shifts;
          result_valid_i  <= result_valid_shifts;
          result_flags_i  <= result_flags_shifts;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
        
        ALU_OPCODE_MOV:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= data_b_r;
          result_valid_i  <= data_valid_r;
          result_flags_i  <= 0;
          single_cycle    <= 1'b1;
          long_opcode     <= 1'b0;
        end
        
        default:
        begin
          ce_logic    <= 1'b0;
          ce_mul      <= 1'b0;
          ce_div_rem  <= 1'b0;
          ce_add_sub  <= 1'b0;
          ce_shifts   <= 1'b0;
          ce_ext      <= 1'b0;
          
          result_i        <= 0;
          result_valid_i  <= 0;
          result_flags_i  <= 0;
          single_cycle    <= 1'b0;
          long_opcode     <= 1'b0;
        end
      endcase
    end
    else
    begin
      ce_logic    <= 1'b0;
      ce_mul      <= 1'b0;
      ce_div_rem  <= 1'b0;
      ce_add_sub  <= 1'b0;
      ce_shifts   <= 1'b0;
      ce_ext      <= 1'b0;
      
      result_i        <= 0;
      result_valid_i  <= 0;
      result_flags_i  <= 0;
      single_cycle <= 1'b0;
    end
  end
  
  // Logic operations
  W0RM_ALU_Logic #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH)
  ) logic (
    .clk(clk),
    
    .data_valid(ce_logic & data_valid_r),
    .opcode(opcode_r),
    
    .data_a(data_a_r),
    .data_b(data_b_r),
    
    .result(result_logic),
    .result_valid(result_valid_logic),
    .result_flags(result_flags_logic)
  );
  
  // Mul
  W0RM_ALU_Multiply #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH)
  ) mul (
    .clk(clk),
    
    .data_valid(ce_mul & data_valid_r),
    .opcode(opcode_r),
    
    .data_a(data_a_r),
    .data_b(data_b_r),
    
    .result(result_mul),
    .result_valid(result_valid_mul),
    .result_flags(result_flags_mul)
  );
  
  // Div/rem
  W0RM_ALU_DivRem #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH)
  ) div_rem (
    .clk(clk),
    
    .data_valid(ce_div_rem & data_valid_r),
    .opcode(opcode_r),
    
    .data_a(data_a_r),
    .data_b(data_b_r),
    
    .result(result_div_rem),
    .result_valid(result_valid_div_rem),
    .result_flags(result_flags_div_rem)
  );
  
  // Add/sub
  W0RM_ALU_AddSub #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH)
  ) add_sub (
    .clk(clk),
    
    .data_valid(ce_add_sub & data_valid_r),
    .opcode(opcode_r),
    
    .data_a(data_a_r),
    .data_b(data_b_r),
    
    .result(result_add_sub),
    .result_valid(result_valid_add_sub),
    .result_flags(result_flags_add_sub)
  );
  
  // Shifts
  W0RM_ALU_Shifts #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH)
  ) shifts (
    .clk(clk),
    
    .data_valid(ce_shifts & data_valid_r),
    .opcode(opcode_r),
    
    .data_a(data_a_r),
    .data_b(data_b_r),
    
    .result(result_shifts),
    .result_valid(result_valid_shifts),
    .result_flags(result_flags_shifts)
  );
  
  // Sign/Zero extend
  W0RM_ALU_Extend #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH)
  ) extend (
    .clk(clk),
    
    .data_valid(ce_ext & data_valid_r),
    .opcode(opcode_r),
    .ext_8_16(ext_bit_size_r),
    
    .data_a(data_a_r),
    .data_b(data_b_r),
    
    .result(result_ext),
    .result_valid(result_valid_ext),
    .result_flags(result_flags_ext)
  );
endmodule
