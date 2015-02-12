`timescale 1ns/100ps

module W0RM_Static_Timer #(
  parameter LOAD  = 0,
  parameter LIMIT = 2
)(
  input wire    clk,
  input wire    start,
  output wire   stop
);
  // log base 2 function
  function integer log2(input integer n);
	integer i, j;
    begin
		i = 1;
		j = 0;
      //integer i = 1, j = 0;
      while (i < n)
      begin
        j = j + 1;
        i = i << 1;
      end
		log2 = j;
    end
  endfunction
  
  localparam TIMER_BITS = log2(LIMIT);
  
  reg [TIMER_BITS-1:0]  timer   = 0;
  reg                   go      = 0;
  reg                   stop_r  = 0;
  
  always @(posedge clk)
  begin
    if (go)
    begin
      if (timer + 1 >= LIMIT)
      begin
        timer   <= 0;
        go      <= 0;
        stop_r  <= 1;
      end
      else
      begin
        timer <= timer + 1;
      end
    end
    else if (start)
    begin
      timer   <= LOAD;
      go      <= 1;
      stop_r  <= 0;
    end
    else
    begin
      go      <= 0;
      timer   <= 0;
      stop_r  <= 0;
    end
  end
  
  assign stop = stop_r;
endmodule
