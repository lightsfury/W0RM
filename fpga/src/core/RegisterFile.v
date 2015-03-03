`timescale 1ns/100ps

module W0RM_Core_RegisterFile #(
  parameter SINGLE_CYCLE  = 0,
  parameter DATA_WIDTH    = 32,
  parameter NUM_REGISTERS = 16,
  parameter NUM_USER_BITS = 64
)(
  clk,
  // Read port 0
  port_read0_addr,
  port_read0_data,
  // Read port 1
  port_read1_addr,
  port_read1_data,
  // Write port
  port_write_addr,
  port_write_enable,
  port_write_data,
  
  reset,
  
  // User data (control, etc)
  user_data_in,
  user_data_out
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
  
  localparam REG_ADDR_BITS = log2(NUM_REGISTERS);

  input wire                        clk;
  
  // Read port 0
  input wire  [REG_ADDR_BITS - 1:0] port_read0_addr;
  output wire [DATA_WIDTH - 1:0]    port_read0_data;
  
  // Read port 1
  input wire  [REG_ADDR_BITS - 1:0] port_read1_addr;
  output wire [DATA_WIDTH - 1:0]    port_read1_data;
  
  // Write port
  input wire  [REG_ADDR_BITS - 1:0] port_write_addr;
  input wire                        port_write_enable;
  input wire  [DATA_WIDTH - 1:0]    port_write_data;
  
  input wire                        reset;
  
  input wire  [NUM_USER_BITS - 1:0] user_data_in;
  output wire [NUM_USER_BITS - 1:0] user_data_out;
  
  // Register file
  reg [DATA_WIDTH - 1:0]  registers [NUM_REGISTERS - 1:0];
  
  reg [DATA_WIDTH - 1:0]  port0_data_r = 0,
                          port1_data_r = 0;

  reg [NUM_USER_BITS-1:0] user_data_r = 0;
                          
  assign port_read0_data  = port0_data_r;
  assign port_read1_data  = port1_data_r;
  assign user_data_out    = user_data_r;
  
  integer i;
  initial
  begin
    for (i = 0;
         i < NUM_REGISTERS;
         i = i + 1)
    begin
      registers[i] = 0;
    end
  end
  
  always @(posedge clk)
  begin
    // Reset action
    if (reset)
    begin
      for (i = 0; i < NUM_REGISTERS; i = i + 1)
      begin
        registers[i] = 0;
      end
    end
    // Write action
    else if (port_write_enable)
    begin
      registers[port_write_addr] <= port_write_data;
      
      // Write before read
      if (port_read0_addr == port_write_addr)
      begin
        port0_data_r <= port_write_data;
      end
      else
      begin
        port0_data_r <= registers[port_read0_addr];
      end
      
      if (port_read1_addr == port_write_addr)
      begin
        port1_data_r <= port_write_data;
      end
      else
      begin
        port1_data_r <= registers[port_read1_addr];
      end
    end
    else
    begin
      // No write action
      port0_data_r <= registers[port_read0_addr];
      port1_data_r <= registers[port_read1_addr];
    end
    
    user_data_r <= user_data_in;
  end
endmodule