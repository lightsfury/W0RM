`timescale 1ns/100ps

module W0RM_Static_Timer_tb;
  reg clk = 0;
  reg start = 0;
  
  always #2.5 clk <= ~clk;
  
  initial
  begin
    #11 start = 1;
    #5  start = 0;
  end
  
  W0RM_Static_Timer #(
    .LOAD(0),
    .LIMIT(7)
  ) timer_0_7 (
    .clk(clk),
    .start(start),
    .stop(stop_timer_0_7)
  );
  
  W0RM_Static_Timer #(
    .LOAD(1),
    .LIMIT(12)
  ) timer_1_12 (
    .clk(clk),
    .start(start),
    .stop(stop_timer_1_12)
  );
  
  W0RM_Static_Timer #(
    .LOAD(0),
    .LIMIT(200)
  ) timer_0_200 (
    .clk(clk),
    .start(start),
    .stop(stop_timer_0_200)
  );
  
  W0RM_Static_Timer #(
    .LOAD(0),
    .LIMIT(4)
  ) timer_0_4 (
    .clk(clk),
    .start(start),
    .stop(stop_timer_0_4)
  );
endmodule
