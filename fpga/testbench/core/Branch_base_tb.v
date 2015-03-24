`timescale 1ns/100ps

module Branch_base_tb #(
  parameter DATA_WIDTH    = 32,
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire   done,
                error
);
  localparam FLAGS_WIDTH    = 4;
  localparam OPCODE_WIDTH   = 4;
  localparam FS_DATA_WIDTH  = (3 * DATA_WIDTH) + 3  + 2;
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
    .ready(fs_go && branch_ready),
    .valid(fs_valid),
    .empty(fs_done),
    .data({data_valid, is_branch, is_cond_branch, branch_rel_abs,
           cond_branch_code, alu_flag_zero, alu_flag_carry, alu_flag_overflow,
           alu_flag_negative, branch_base_addr, rn, lit})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    .valid(result_valid),
    .data({}),
    .done(done),
    .error(error)
  );
  
  W0RM_Core_Branch #(
    .SINGLE_CYCLE(0),
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(1)
  ) dut (
    .clk(clk),
    
    .mem_ready(1'b1),
    .branch_ready(branch_ready),
    
    .data_valid(fs_valid && valid),
    .is_branch(is_branch),
    .is_cond_branch(is_cond_branch),
    .cond_branch_code(cond_branch_code),
    
    .alu_flag_zero(alu_flag_zero),
    .alu_flag_negative(alu_flag_negative),
    .alu_flag_carry(alu_flag_carry),
    .alu_flag_overflow(alu_flag_overflow),
    
    .branch_base_addr(branch_base_addr),
    .branch_rel_abs(branch_rel_abs),
    
    .rn(rn),
    .lit(lit),
    
    .branch_valid(branch_valid),
    .flush_pipeline(flush),
    .next_pc(next_pc),
    .next_pc_valid(next_pc_valid),
    
    .user_data_in(1'b0),
    .user_data_out() // Not used
  );
endmodule
