`timescale 1ns/100ps

module W0RM_ALU_Multiply #(
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
  
  localparam ALU_OPCODE_MUL = 4'h5;
  
  localparam ALU_FLAG_ZERO  = 4'h0;
  localparam ALU_FLAG_NEG   = 4'h1;
  localparam ALU_FLAG_OVER  = 4'h2;
  localparam ALU_FLAG_CARRY = 4'h3;
  
  reg   [DATA_WIDTH-1:0]      result_r = 0,
                              data_a_r = 0,
                              data_b_r = 0;
  reg                         flag_carry_r = 0,
                              result_valid_r = 0;
  wire  [(2*DATA_WIDTH)-1:0]  result_i;
  wire                        result_valid_i;
  
  assign result_flags[ALU_FLAG_ZERO]  = result_r == 0;
  assign result_flags[ALU_FLAG_NEG]   = result_r[MSB];
  assign result_flags[ALU_FLAG_OVER]  = ((~result_r[MSB]) && data_a_r[MSB] && data_b_r[MSB]) ||
                                        (result_r[MSB] && (~data_a_r[MSB]) && (~data_b_r[MSB]));
  assign result_flags[ALU_FLAG_CARRY] = flag_carry_r; // Carry generated by IP core
  
  assign result = result_r;
  assign result_valid = result_valid_r;
  
  always @(posedge clk)
  begin
    if (result_valid_i)
    begin
      flag_carry_r  <= result_i[DATA_WIDTH];
      result_r      <= result_i[DATA_WIDTH-1:0];
    end
    
    if (data_valid)
    begin
      data_a_r  <= data_a;
      data_b_r  <= data_b;
    end
    
    result_valid_r  <= result_valid_i;
  end
  
  W0RM_Static_Timer #(
    .LOAD(0),
    .LIMIT(13)
  ) valid_delay (
    .clk(clk),
    
    .start(data_valid),
    .stop(result_valid_i)
  );
  
  W0RM_Int_Mul mul(
    .clk(clk),
    
    .a(data_a),
    .b(data_b),
    
    .p(result_i)
  );

endmodule