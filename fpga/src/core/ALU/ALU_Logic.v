`timescale 1ns/100ps

module W0RM_ALU_Logic #(
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
  localparam MSB            = DATA_WIDTH - 1;
  
  localparam ALU_OPCODE_AND = 4'h0;
  localparam ALU_OPCODE_OR  = 4'h1;
  localparam ALU_OPCODE_XOR = 4'h2;
  localparam ALU_OPCODE_NOT = 4'h3;
  localparam ALU_OPCODE_NEG = 4'h4;
  
  localparam ALU_FLAG_ZERO  = 4'h0;
  localparam ALU_FLAG_NEG   = 4'h1;
  localparam ALU_FLAG_OVER  = 4'h2;
  localparam ALU_FLAG_CARRY = 4'h3;
  
  reg [DATA_WIDTH-1:0]  result_r = 0,
                        data_a_r = 0,
                        data_b_r = 0;
  reg                   result_valid_r  = 0;
  reg [DATA_WIDTH-1:0]  result_i        = 0;
  reg                   result_valid_i  = 0;
  
  assign result       = result_r;
  assign result_valid = result_valid_r;
  
  assign result_flags[ALU_FLAG_ZERO]  = result_r == 0;
  assign result_flags[ALU_FLAG_NEG]   = result_r[MSB];
  assign result_flags[ALU_FLAG_OVER]  = ((~result_r[MSB]) && data_a_r[MSB] && data_b_r[MSB]) ||
                                        (result_r[MSB] && (~data_a_r[MSB]) && (~data_b_r[MSB]));
  assign result_flags[ALU_FLAG_CARRY] = 1'b0; // Carry not defined for logic ops
  
  always @(data_valid, opcode, data_a, data_b)
  begin
    result_valid_i = data_valid;
    
    if (data_valid)
    begin
      case (opcode)
        ALU_OPCODE_AND:
        begin
          result_i = data_a & data_b;
        end
        
        ALU_OPCODE_OR:
        begin
          result_i = data_a | data_b;
        end
        
        ALU_OPCODE_XOR:
        begin
          result_i = data_a ^ data_b;
        end
        
        ALU_OPCODE_NOT:
        begin
          result_i = ~data_a;
        end
        
        ALU_OPCODE_NEG:
        begin
          result_i = ~data_a + 1;
        end
        
        default:
        begin
          result_i  = {DATA_WIDTH{1'b0}};
        end
      endcase
    end
    else
    begin
      result_i = {DATA_WIDTH{1'b0}};
    end
  end
  
  generate
    if (SINGLE_CYCLE)
    begin
      always @(data_a, data_b, result_i, result_valid_i)
      begin
        data_a_r        = data_a;
        data_b_r        = data_b;
        result_r        = result_i;
        result_valid_r  = result_valid_i;
      end
    end
    else
    begin
      always @(posedge clk)
      begin
        result_valid_r <= data_valid;
        if (data_valid)
        begin
          data_a_r  <= data_a;
          data_b_r  <= data_b;
          
          result_r  <= result_i;
        end
      end
    end
  endgenerate
endmodule
