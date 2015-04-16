`timescale 1ns/100ps

module W0RM_Sync_ALU_base_tb #(
  parameter DATA_WIDTH    = 8,
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire   done,
                error
);
  localparam OPCODE_WIDTH   = 4;
  localparam SYNC_WIDTH     = OPCODE_WIDTH + (2 * DATA_WIDTH);
  localparam FS_DATA_WIDTH  = 1 + SYNC_WIDTH;
  localparam FC_DATA_WIDTH  = DATA_WIDTH;
  
  reg   clk = 0;
  reg   fs_pause = 1;
  wire  fs_done;
  
  wire                    valid_i,
                          valid_o;
  wire  [DATA_WIDTH-1:0]  data_i,
                          data_o;
  
  always #2.5 clk <= ~clk;
  
  initial #50 fs_pause <= 1'b0;
  
  FileSource #(
    .DATA_WIDTH(FS_DATA_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    .ready(sync_ready && ~fs_pause),
    .valid(fs_valid),
    .empty(fs_done),
    .data({valid_i, data_i})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    .valid(alu_result_valid),
    .data(alu_result),
    .done(done),
    .error(error)
  );
  
  W0RM_Synchro #(
    .DATA_WIDTH(SYNC_WIDTH),
    .SYNC_READY(0)
  ) dut (
    .clk(clk),
    .reset(fs_pause),
    
    .input_valid(valid_i && fs_valid),
    .input_ready(sync_ready),
    .input_data(data_i),
    
    .output_valid(valid_o),
    .output_ready(alu_ready),
    .output_data({alu_opcode, alu_op1, alu_op2})
  );
  
  W0RM_Core_ALU #(
    .SINGLE_CYCLE(1),
    .DATA_WIDTH(8),
    .USER_WIDTH(1)
  ) alu (
    .clk(),
    
    .opcode(alu_opcode),
    .flush(1'b0),
    
    .mem_ready(1'b1),
    .alu_ready(alu_ready),
    .data_valid(valid_o),
    .store_flags_mask(4'h0),
    .ext_bit_size(1'b0),
    
    .data_a(alu_op1),
    .data_b(alu_op2),
    
    .result(alu_result),
    .result_forward(),
    .result_valid(alu_result_valid),
    
    .flag_zero(),
    .flag_negative(),
    .flag_overflow(),
    .flag_carry(),
    
    .result_flags_forward(),
    
    .user_data_in(1'b0),
    .user_data_out()
  );
endmodule
