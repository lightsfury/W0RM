`timescale 1ns/100ps

module W0RM_Sync_base_tb #(
  parameter DATA_WIDTH    = 8,
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire   done,
                error
);
  localparam FS_DATA_WIDTH  = 1 + DATA_WIDTH;
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
    .valid(valid_o),
    .data(data_o),
    .done(done),
    .error(error)
  );
  
  W0RM_Synchro #(
    .DATA_WIDTH(DATA_WIDTH),
    .SYNC_READY(0)
  ) dut (
    .clk(clk),
    .reset(fs_pause),
    
    .input_valid(valid_i && fs_valid),
    .input_ready(sync_ready),
    .input_data(data_i),
    
    .output_valid(valid_o),
    .output_ready(1'b1),
    .output_data(data_o)
  );
endmodule
