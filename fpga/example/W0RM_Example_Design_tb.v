`timescale 1ns/100ps

module W0RM_Example_Design_tb;
  reg clk = 0;
  reg reset = 0;
  
  wire  [7:0] leds;
  
  initial #11 reset = 1;
  
  always #2.5 clk <= ~clk;

  W0RM_Example_Design dut(
    .sysclk_p(clk),
    .sysclk_n(~clk),
    .cpu_reset(reset),
    
    .leds(leds),
    .led_north(led_north)
  );
endmodule
