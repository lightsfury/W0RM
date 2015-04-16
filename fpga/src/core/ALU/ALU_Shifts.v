`timescale 1ns/100ps

module W0RM_ALU_Shifts #(
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
  // log base 2 function
  function integer log2(input integer n);
	integer i, j;
    begin
      i = 1;
      j = 0;
      while (i < n)
      begin
        j = j + 1;
        i = i << 1;
      end
		log2 = j;
    end
  endfunction
  
  function integer pow2(input integer n);
  integer i, j;
    begin
      i = 0;
      j = 1;
      while (i < n)
      begin
        i = i + 1;
        j = j * 2;
      end
      pow2 = j;
    end
  endfunction

  localparam MSB            = DATA_WIDTH - 1;
  localparam SHIFT_SIZE     = log2(DATA_WIDTH);
  
  localparam ALU_OPCODE_LSR = 4'hc;
  localparam ALU_OPCODE_LSL = 4'hd;
  localparam ALU_OPCODE_ASR = 4'he;
  
  localparam ALU_FLAG_ZERO  = 4'h0;
  localparam ALU_FLAG_NEG   = 4'h1;
  localparam ALU_FLAG_OVER  = 4'h2;
  localparam ALU_FLAG_CARRY = 4'h3;

  reg   [3:0]             opcode_r = 0;
  reg   [DATA_WIDTH-1:0]  result_r = 0,
                          data_a_r = 0,
                          data_b_r = 0;
  reg                     flag_carry_r = 0,
                          data_valid_r1 = 0,
                          result_valid_r = 0;
  wire  [DATA_WIDTH-1:0]  add_sub_result;
  wire                    flag_carry;
  
  reg [DATA_WIDTH-1:0]  result_i[SHIFT_SIZE:0];
  
  integer i;
  initial
  begin
    for (i = 0; i < SHIFT_SIZE; i = i + 1)
    begin
      result_i[i] = {DATA_WIDTH{1'b0}};
    end
  end
  
  assign result_flags[ALU_FLAG_ZERO]  = result_r == 0;
  assign result_flags[ALU_FLAG_NEG]   = result_r[MSB];
  assign result_flags[ALU_FLAG_OVER]  = ((~result_r[MSB]) && data_a_r[MSB] && data_b_r[MSB]) ||
                                        (result_r[MSB] && (~data_a_r[MSB]) && (~data_b_r[MSB]));
  assign result_flags[ALU_FLAG_CARRY] = flag_carry_r; // Carry generated by IP core
  
  assign result = result_r;
  assign result_valid = result_valid_r;
  
  generate
    if (SINGLE_CYCLE)
    begin
      always @(*)
      begin
        data_valid_r1 = data_valid;
        
        if (data_valid)
        begin
          opcode_r    = opcode;
          data_a_r    = data_a;
          data_b_r    = data_b;
          result_i[0] = data_a;
        end
        else
        begin
          opcode_r    = 4'd0;
          data_a_r    = {DATA_WIDTH{1'b0}};
          data_b_r    = {DATA_WIDTH{1'b0}};
          result_i[0] = {DATA_WIDTH{1'b0}};
        end
        
        data_valid_r1   = data_valid;
        result_valid_r  = data_valid_r1;
        result_r        = result_i[SHIFT_SIZE];
        
      end
    end
    else
    begin
      always @(posedge clk)
      begin
        if (data_valid)
        begin
          opcode_r      <= opcode;
          data_a_r      <= data_a;
          data_b_r      <= data_b;
          
          result_i[0]   <= data_a;
        end
        
        data_valid_r1   <= data_valid;
        result_valid_r  <= data_valid_r1;
        result_r        <= result_i[SHIFT_SIZE];
      end
    end
  endgenerate
  
  /*
  always @(posedge clk)
  begin
    if (data_valid)
    begin
      opcode_r      <= opcode;
      data_a_r      <= data_a;
      data_b_r      <= data_b;
      
      result_i[0]   <= data_a;
    end
    
    data_valid_r1   <= data_valid;
    result_valid_r  <= data_valid_r1;
    result_r        <= result_i[SHIFT_SIZE];
  end // */
  
  genvar  shift_count;
  generate
    for (shift_count = 0; shift_count < SHIFT_SIZE; shift_count = shift_count + 1)
    begin : shifter
      always @(*)
      begin
        if (data_b_r[shift_count])
        begin
          case (opcode_r)
            ALU_OPCODE_LSL:
            begin
              result_i[shift_count+1] = {(result_i[shift_count][DATA_WIDTH-pow2(shift_count):0]), 
                                         {(pow2(shift_count)){1'b0}}};
            end
            
            ALU_OPCODE_LSR:
            begin
              result_i[shift_count+1] = {{pow2(shift_count+1){1'b0}},
                                         (result_i[shift_count][DATA_WIDTH-1:pow2(shift_count+1)-1])};
            end
            
            ALU_OPCODE_ASR:
            begin
              result_i[shift_count+1] = {{result_i[shift_count][MSB],
                                         {{(pow2(shift_count+1) - 1){result_i[shift_count][MSB]}}}},
                                         (result_i[shift_count][DATA_WIDTH-1:pow2(shift_count+1)-1])};
            end
            
            default:
            begin
              result_i[shift_count+1] = result_i[shift_count];
            end
          endcase
        end
        else
        begin
          result_i[shift_count+1] = result_i[shift_count];
        end
      end
    end
  endgenerate
endmodule
