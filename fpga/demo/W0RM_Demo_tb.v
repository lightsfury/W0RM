`timescale 1ns/100ps

module W0RM_Demo_tb;
  reg clk = 0;
  reg reset_n = 0;
  
  initial #11 reset_n = 1;
  
  always #2.5 clk <= ~clk;
  
  wire [7:0]  switches, leds;
  
  assign switches = 8'h80;
  
  W0RM_Demo dut(
    .sysclk_p(clk),
    .sysclk_n(~clk),
    .cpu_reset(reset_n),
    .gpio_a(switches),
    .gpio_b(leds)
  );
endmodule
