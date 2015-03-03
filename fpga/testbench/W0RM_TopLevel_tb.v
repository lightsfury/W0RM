`timescale 1ns/100ps

module W0RM_TopLevel_tb;
  reg clk = 0, reset = 1;
  
  initial #11 reset = 0;
  
  always #2.5 clk <= ~clk;
  
  W0RM_TopLevel #(
    .SINGLE_CYCLE(0),
    .INST_CACHE(0)
  ) dut (
    .BaseCLK(clk),
    .Reset(reset),
    
    .Address_o(),
    .Data_o(),
    .Read_o(),
    .Write_o(),
    .Valid_o(),
    
    .Data_i(32'd0),
    .Valid_i(1'b0)
  );
endmodule
