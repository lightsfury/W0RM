`timescale 1ns/100ps

module W0RM_Decode_1_tb;
  reg clk = 0;
  
  always #2.5 clk <= ~clk;

  W0RM_Core_Decode dut (
    .clk(clk),
    .instruction(16'd0),
    .inst_valid(1'b0),
    .fetch_ready(1'b0)
  );
endmodule
