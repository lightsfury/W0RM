`timescale 1ns/100ps

module ALU_Core_base_tb #(
  parameter DATA_WIDTH    = 32,
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire   done,
                error
);
  localparam FLAGS_WIDTH    = 4;
  localparam OPCODE_WIDTH   = 4;
  localparam FS_DATA_WIDTH  = (2 * DATA_WIDTH) + OPCODE_WIDTH + 2;
  localparam FC_DATA_WIDTH  = DATA_WIDTH;
  
  reg   clk = 0;
  reg   fs_go = 0;
  reg   fs_pause = 1;
  reg   first_run = 1;
  wire  fs_done;
  
  wire                    valid;
  wire  [DATA_WIDTH-1:0]  data_a,
                          data_b;
  wire  [3:0]             opcode;
  
  wire                    result_valid;
  wire  [DATA_WIDTH-1:0]  result;
  wire  [FLAGS_WIDTH-1:0] result_flags;
  
  always #2.5 clk <= ~clk;
  
  initial #50 fs_pause <= 1'b0;
  
  always @(posedge clk)
  begin
    if (fs_pause)
    begin
      fs_go <= 0;
    end
    else
    begin
      if (first_run)
      begin
        if (fs_go)
        begin
          fs_go <= 0;
          first_run <= 0;
        end
        else
        begin
          fs_go <= 1;
        end
      end
      else
      begin
        fs_go <= result_valid;
      end
    end
  end
  
  FileSource #(
    .DATA_WIDTH(FS_DATA_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    .ready(fs_go),
    .valid(valid),
    .empty(fs_done),
    .data({data_valid, ext_8_16, opcode, data_a, data_b})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    .valid(result_valid),
    .data(result),
    .done(done),
    .error(error)
  );
  
  W0RM_Core_ALU #(
    .SINGLE_CYCLE(0),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk(clk),
    
    .data_valid(valid & data_valid),
    .opcode(opcode),
    .store_flags_mask(4'h0),
    .ext_bit_size(ext_8_16),
    
    .data_a(data_a),
    .data_b(data_b),
    
    .result(result),
    .result_valid(result_valid),
    .flag_zero(flag_zero),
    .flag_negative(flag_negative),
    .flag_overflow(flag_overflow),
    .flag_carry(flag_carry)
  );
endmodule
