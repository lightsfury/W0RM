`timescale 1ns/100ps

module W0RM_ALU_Extend #(
  parameter SINGLE_CYCLE  = 0,
  parameter DATA_WIDTH    = 8
)(
  input wire                    clk,
  
  input wire                    data_valid,
  input wire  [3:0]             opcode,
  input wire                    ext_8_16, // High for 16-bit, low for 8-bit
  
  input wire  [DATA_WIDTH-1:0]  data_a,
                                data_b,
  
  output wire [DATA_WIDTH-1:0]  result,
  output wire                   result_valid,
  output wire [3:0]             result_flags
);
  localparam MSB            = DATA_WIDTH - 1;
  
  localparam ALU_OPCODE_SEX = 4'ha;
  localparam ALU_OPCODE_ZEX = 4'hb;
  
  localparam ALU_FLAG_ZERO  = 4'h0;
  localparam ALU_FLAG_NEG   = 4'h1;
  localparam ALU_FLAG_OVER  = 4'h2;
  localparam ALU_FLAG_CARRY = 4'h3;
  
  reg   [DATA_WIDTH-1:0]  result_r = 0;
  reg                     result_valid_r = 0;
  reg   [DATA_WIDTH-1:0]  result_i = 0;
  reg                     result_valid_i = 0;
  
  assign result_flags[ALU_FLAG_ZERO]  = result_r == 0;
  assign result_flags[ALU_FLAG_NEG]   = result_r[MSB];
  assign result_flags[ALU_FLAG_OVER]  = 1'b0; // Overflow and carry are not
  assign result_flags[ALU_FLAG_CARRY] = 1'b0; // defined for extend operations
  
  assign result = result_r;
  assign result_valid = result_valid_r;
  
  always @(data_valid, opcode, ext_8_16, data_a)
  begin
    result_valid_i = data_valid;
    if (data_valid)
    begin
      case (opcode)
        ALU_OPCODE_SEX:
        begin
          if (ext_8_16)
          begin
            // 16-bit
            result_i  = {{16{data_a[15]}}, data_a[15:0]};
          end
          else
          begin
            // 8-bit
            result_i  = {{24{data_a[7]}}, data_a[7:0]};
          end
        end
        
        ALU_OPCODE_ZEX:
        begin
          if (ext_8_16)
          begin
            // 16-bit
            result_i  = {16'd0, data_a[15:0]};
          end
          else
          begin
            // 8-bit
            result_i  = {24'd0, data_a[7:0]};
          end
        end
        
        default:
        begin
          result_i    = 0;
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
      always @(result_i, result_valid_i)
      begin
        result_r        = result_i;
        result_valid_r  = result_valid_i;
      end
    end
    else
    begin
      always @(posedge clk)
      begin
        result_r <= result_i;
        result_valid_r <= result_valid_i;
      end
    end
  endgenerate
endmodule
