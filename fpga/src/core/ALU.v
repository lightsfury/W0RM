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
                                result_forward,
  output wire                   result_valid,
  output wire                   flag_zero,
                                flag_negative,
                                flag_overflow,
                                flag_carry,
  output wire [3:0]             result_flags_forward,
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
                          data_b_r = 0;
  //reg   [DATA_WIDTH-1:0]  result_r = 0;
  reg                     data_valid_r = 0;
  //reg                     result_valid_r = 0;
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
  reg   [3:0]             result_flags_i = 0;
  
  reg   [DATA_WIDTH-1:0]  result_i = 0;
  reg                     result_valid_i = 0;
  reg   [3:0]             result_flags_temp = 0;
  
  reg   ce_logic    = 0,
        ce_mul      = 0,
        ce_div_rem  = 0,
        ce_add_sub  = 0,
        ce_shifts   = 0,
        ce_ext      = 0;
  
  reg   [USER_WIDTH-1:0]  user_data_r = 0;
  //                        user_data_r2 = 0;
  reg                     long_opcode = 0;
  reg                     ext_bit_size_r = 0;
  
  assign result          = result_i;
  assign result_forward  = result_i;
  assign result_valid    = result_valid_i && data_valid_r;
  assign flag_zero       = result_flags_r[ALU_FLAG_ZERO];
  assign flag_negative   = result_flags_r[ALU_FLAG_NEG];
  assign flag_overflow   = result_flags_r[ALU_FLAG_OVER];
  assign flag_carry      = result_flags_r[ALU_FLAG_CARRY];
  assign alu_ready            = mem_ready && (~data_valid_r || result_valid_i);
  assign user_data_out   = user_data_r;
  assign result_flags_forward = result_flags_temp;
  
  always @(posedge clk)
  begin
    if (flush)
    begin
      opcode_r    <= 4'd0;
      data_a_r    <= {DATA_WIDTH{1'b0}};
      data_b_r    <= {DATA_WIDTH{1'b0}};
      user_data_r <= {USER_WIDTH{1'b0}};
    end
    else if (mem_ready)
    begin
      if (data_valid && (~data_valid_r || ~long_opcode || result_valid_i))
      begin
        data_valid_r        <= 1'b1;
        opcode_r            <= opcode;
        store_flags_mask_r  <= store_flags_mask;
        ext_bit_size_r      <= ext_bit_size;
        data_a_r            <= data_a;
        data_b_r            <= data_b;
        user_data_r         <= user_data_in;
      end
      
      // We have a previous instruction and it is complete
      if (data_valid_r && result_valid_i)
      begin
        // Register its data
        //user_data_r     <= user_data_in;
        data_valid_r    <= data_valid;
        //result_r        <= result_i;
        //result_valid_r  <= result_valid_i;
        result_flags_r  <= result_flags_temp;
        if (!data_valid)
        begin
          user_data_r   <= {USER_WIDTH{1'b0}};
        end
      end
    end
  end
  
  always @(data_valid_r, opcode_r, result_logic, result_valid_logic,
           result_flags_logic, result_mul, result_valid_mul, result_flags_mul,
           result_div_rem, result_valid_div_rem, result_flags_div_rem,
           result_ext, result_valid_ext, result_flags_ext,
           result_shifts, result_valid_shifts, result_flags_shifts,
           result_add_sub, result_valid_add_sub, result_flags_add_sub,
           result_add_sub, result_valid_add_sub, result_flags_add_sub)
  begin
    if (data_valid_r)
    begin
      case (opcode_r)
        ALU_OPCODE_AND:
        begin
          ce_logic    = 1'b1;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_logic;
          result_valid_i  = result_valid_logic;
          result_flags_i  = result_flags_logic;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_OR:
        begin
          ce_logic    = 1'b1;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_logic;
          result_valid_i  = result_valid_logic;
          result_flags_i  = result_flags_logic;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_XOR:
        begin
          ce_logic    = 1'b1;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_logic;
          result_valid_i  = result_valid_logic;
          result_flags_i  = result_flags_logic;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_NOT:
        begin
          ce_logic    = 1'b1;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_logic;
          result_valid_i  = result_valid_logic;
          result_flags_i  = result_flags_logic;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_NEG:
        begin
          ce_logic    = 1'b1;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_logic;
          result_valid_i  = result_valid_logic;
          result_flags_i  = result_flags_logic;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_MUL:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b1;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_mul;
          result_valid_i  = result_valid_mul;
          result_flags_i  = result_flags_mul;
          long_opcode     = 1'b1;
        end
        
        ALU_OPCODE_DIV:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b1;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_div_rem;
          result_valid_i  = result_valid_div_rem;
          result_flags_i  = result_flags_div_rem;
          long_opcode     = 1'b1;
        end
        
        ALU_OPCODE_REM:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b1;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_div_rem;
          result_valid_i  = result_valid_div_rem;
          result_flags_i  = result_flags_div_rem;
          long_opcode     = 1'b1;
        end
        
        ALU_OPCODE_ADD:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b1;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_add_sub;
          result_valid_i  = result_valid_add_sub;
          result_flags_i  = result_flags_add_sub;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_SUB:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b1;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = result_add_sub;
          result_valid_i  = result_valid_add_sub;
          result_flags_i  = result_flags_add_sub;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_SEX:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b1;
          
          result_i        = result_ext;
          result_valid_i  = result_valid_ext;
          result_flags_i  = result_flags_ext;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_ZEX:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b1;
          
          result_i        = result_ext;
          result_valid_i  = result_valid_ext;
          result_flags_i  = result_flags_ext;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_LSR:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b1;
          ce_ext      = 1'b0;
          
          result_i        = result_shifts;
          result_valid_i  = result_valid_shifts;
          result_flags_i  = result_flags_shifts;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_LSL:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b1;
          ce_ext      = 1'b0;
          
          result_i        = result_shifts;
          result_valid_i  = result_valid_shifts;
          result_flags_i  = result_flags_shifts;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_ASR:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b1;
          ce_ext      = 1'b0;
          
          result_i        = result_shifts;
          result_valid_i  = result_valid_shifts;
          result_flags_i  = result_flags_shifts;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        ALU_OPCODE_MOV:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = data_b_r;
          result_valid_i  = data_valid_r;
          result_flags_i  = 0;
          long_opcode     = (SINGLE_CYCLE) ? 1'b0 : 1'b1;
        end
        
        default:
        begin
          ce_logic    = 1'b0;
          ce_mul      = 1'b0;
          ce_div_rem  = 1'b0;
          ce_add_sub  = 1'b0;
          ce_shifts   = 1'b0;
          ce_ext      = 1'b0;
          
          result_i        = 0;
          result_valid_i  = 0;
          result_flags_i  = 0;
          long_opcode     = 0;
        end
      endcase
    end
    else
    begin
      ce_logic    = 1'b0;
      ce_mul      = 1'b0;
      ce_div_rem  = 1'b0;
      ce_add_sub  = 1'b0;
      ce_shifts   = 1'b0;
      ce_ext      = 1'b0;
      
      result_i        = 0;
      result_valid_i  = 0;
      result_flags_i  = 0;
      long_opcode     = 0;
    end
  end
  
  always @(store_flags_mask_r, result_flags_i, result_flags_r)
  begin
    if (store_flags_mask_r[0])
    begin
      result_flags_temp[0]  = result_flags_i[0];
    end
    else
    begin
      result_flags_temp[0]  = result_flags_r[0];
    end
    
    if (store_flags_mask_r[1])
    begin
      result_flags_temp[1]  = result_flags_i[1];
    end
    else
    begin
      result_flags_temp[1]  = result_flags_r[1];
    end
    
    if (store_flags_mask_r[2])
    begin
      result_flags_temp[2]  = result_flags_i[2];
    end
    else
    begin
      result_flags_temp[2]  = result_flags_r[2];
    end
    
    if (store_flags_mask_r[3])
    begin
      result_flags_temp[3]   = result_flags_i[3];
    end
    else
    begin
      result_flags_temp[3]  = result_flags_r[3];
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
