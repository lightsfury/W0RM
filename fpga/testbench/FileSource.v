`timescale 1ns/100ps

module FileSource #(
  parameter DATA_WIDTH  = 32,
  parameter FILE_PATH   = ""
)(
  input wire                    clk,
  input wire                    ready,
  output wire                   valid,
                                empty,
  output wire [DATA_WIDTH-1:0]  data
);
  reg [DATA_WIDTH-1:0]  data_r = 0;
  reg                   valid_r = 0;
  reg                   empty_r = 0;
  
  assign data   = data_r;
  assign valid  = valid_r;
  assign empty  = empty_r;
  
  integer fileHandle;
  integer status1;
  
  initial begin
    fileHandle = $fopen(FILE_PATH, "r");
  end
  
  always @(posedge clk)
  begin
    if (ready && ~empty_r)
    begin
      status1 = $fscanf(fileHandle, "%x\n", data_r);
    end
    
    valid_r <= ready && ~empty_r;
    empty_r <= (fileHandle == 0) || ($feof(fileHandle));
  end
endmodule
