`timescale 1ns/100ps

module ALU_Mul_base_tb #(
  parameter DATA_WIDTH    = 8,
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire   done,
                error
);
  localparam FLAGS_WIDTH    = 4;
  localparam OPCODE_WIDTH   = 4;
  localparam FS_DATA_WIDTH  = (2 * DATA_WIDTH) + OPCODE_WIDTH + 1;
  localparam FC_DATA_WIDTH  = (FLAGS_WIDTH - 1) + DATA_WIDTH;
  
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
  
  //initial #50 fs_go <= 1'b1;
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
    .data({data_valid, opcode, data_a, data_b})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    .valid(result_valid),
    .data({result_flags[2:0], result}),
    .done(done),
    .error(error)
  );
  
  W0RM_ALU_Multiply #(
    .SINGLE_CYCLE(0),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk(clk),
    .data_valid(valid & data_valid),
    .opcode(opcode),
    
    .data_a(data_a),
    .data_b(data_b),
    
    .result(result),
    .result_valid(result_valid),
    .result_flags(result_flags)
  );
endmodule
