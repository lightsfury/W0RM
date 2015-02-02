`timescale 1ns/1ns

module FileCompare #(
  parameter DATA_WIDTH  = 32,
  parameter FILE_PATH   = ""
)(
  input wire                    clk,
  input wire                    valid,
  input wire  [DATA_WIDTH-1:0]  data,
  output wire                   done,
  output wire                   error
);
  integer fileHandle;
  integer status1;
  
  initial begin
    fileHandle = $fopen(FILE_PATH, "r");
    $display("FileCompare [%d], opening '%s': %d\n", DATA_WIDTH, FILE_PATH, fileHandle);
  end
  
  reg done_r = 0;
  reg error_r = 0;
  
  reg [DATA_WIDTH-1:0]  data_i = 0,
                        data_r = 0;
  
  reg empty_r = 0;
  
  always #1 empty_r <= $feof(fileHandle);
  
  assign error  = error_r;
  assign done   = done_r;
  
  always @(posedge clk)
  begin
    if (valid && ~done_r)
    begin
      status1 = $fscanf(fileHandle, "%x\n", data_i);
      data_r <= data;
      
      if (data_i != data)
      begin
        error_r <= 1'b1;
      end
    end
    else
    begin
      error_r <= error_r;
    end
    
    done_r <= (fileHandle == 0) || $feof(fileHandle);
  end
endmodule
