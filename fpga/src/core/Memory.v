`timescale 1ns/100ps


module W0RM_Core_Memory #(
  parameter SINGLE_CYCLE  = 0,
  parameter USER_WIDTH    = 1,
  parameter ADDR_WIDTH    = 32,
  parameter DATA_WIDTH    = 32
)(
  input wire                    clk,
  
  output wire                   mem_ready,
                                mem_output_valid,
  output wire [DATA_WIDTH-1:0]  mem_data_out
  
  input wire                    mem_write,
                                mem_read,
                                mem_is_pop,
  input wire  [1:0]             mem_data_src,
                                mem_addr_src,

  output wire                   data_bus_write_out,
                                data_bus_read_out,
                                data_bus_valid_out,
  output wire [ADDR_WIDTH-1:0]  data_bus_addr_out,
  output wire [DATA_WIDTH-1:0]  data_bus_data_out,
  
  input wire  [DATA_WIDTH-1:0]  data_bus_data_in,
  input wire                    data_bus_valid_in,
  
  input wire  [USER_WIDTH-1:0]  user_data_in,
  output wire [USER_WIDTH-1:0]  user_data_out
);
  reg   [USER_WIDTH-1:0]  user_data_r = 0;
  
  always @(posedge clk)
  begin 
  end
endmodule
