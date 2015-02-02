`timescale 1ns/100ps

module W0RM_Core_ALU #(
  parameter SINGLE_CYCLE  = 0,
  parameter DATA_WIDTH    = 8
)(
  input wire                    clk,
  // Operation port
  input wire  [3:0]             opcode,
  // Control port
  input wire                    data_valid,
  input wire  [3:0]             store_flags_mask,
  // Data in port
  input wire  [DATA_WIDTH-1:0]  data_a,
                                data_b,
  // Data out port
  output wire [DATA_WIDTH-1:0]  result,
  output wire                   flag_zero,
                                flag_negative,
                                flag_overflow,
                                flag_carry
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
  //                          4'ha; // Unused
  //                          4'hb; // Unused
  localparam ALU_OPCODE_LSR = 4'hc;
  localparam ALU_OPCODE_RSR = 4'hd;
  localparam ALU_OPCODE_ASR = 4'he;
  //                          4'hf; // Unused
  
  localparam ALU_FLAG_ZERO  = 4'h0;
  localparam ALU_FLAG_NEG   = 4'h1;
  localparam ALU_FLAG_OVER  = 4'h2;
  localparam ALU_FLAG_CARRY = 4'h3;
  
  reg [3:0]             opcode_r = 0;
  reg [DATA_WIDTH-1:0]  data_a_r = 0,
                        data_b_r = 0;
  reg                   data_valid_r = 0;
  
  always @(posedge clk)
  begin
    data_valid_r <= data_valid;
    
    if (data_valid && ~pending_op)
    begin
      opcode_r    <= opcode;
      data_a_r    <= data_a;
      data_b_r    <= data_b;
      pending_op  <= 1'b1;
    end
    
    if (ret_data_valid && pending_op)
    begin
      pending_op <= 1'b0;
      
      // demux to output data register & valid
    end
  end
  
  always @(opcode_r)
  begin
    case (opcode_r)
      ALU_OPCODE_AND:
      begin
        ce_logic    <= 1'b1;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_OR:
      begin
        ce_logic    <= 1'b1;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_XOR:
      begin
        ce_logic    <= 1'b1;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_NOT:
      begin
        ce_logic    <= 1'b1;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_NEG:
      begin
        ce_logic    <= 1'b1;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_MUL:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b1;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_DIV:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b1;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_REM:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b1;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_ADD:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b1;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_SUB:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b1;
        ce_shifts   <= 1'b0;
      end
      
      ALU_OPCODE_LSR:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b1;
      end
      
      ALU_OPCODE_RSR:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b1;
      end
      
      ALU_OPCODE_ASR:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b1;
      end
      
      default:
      begin
        ce_logic    <= 1'b0;
        ce_mul      <= 1'b0;
        ce_div_rem  <= 1'b0;
        ce_add_sub  <= 1'b0;
        ce_shifts   <= 1'b0;
      end
    endcase
  end
  
  // Logic operations
  W0RM_ALU_Logic #(
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DATA_WIDTH(DATA_WIDTH)
  ) logic (
    .clk(clk),
    
    .data_valid(ce_logic),
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
    
    .data_valid(ce_mul),
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
    
    .data_valid(ce_div_rem),
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
    
    .data_valid(ce_add_sub),
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
    
    .data_valid(ce_shifts),
    .opcode(opcode_r),
    
    .data_a(data_a_r),
    .data_b(data_b_r),
    
    .result(result_shifts),
    .result_valid(result_valid_shifts),
    .result_flags(result_flags_shifts)
  );
endmodule