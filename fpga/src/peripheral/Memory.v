`timescale 1ns/100ps

module W0RM_Peripheral_MemoryBlock #(
  parameter ADDR_WIDTH  = 32,
  parameter DATA_WIDTH  = 32,
  parameter MEM_DEPTH   = 512,
  parameter BASE_ADDR   = 32'h4000_0000,
  parameter INIT_FILE   = "",
  parameter USER_WIDTH  = 32,
  parameter USE_BRAM    = 0
)(
  input wire                    mem_clk,
  input wire                    cpu_reset,
  
  // Port A
  input wire                    mem_a_valid_i,
                                mem_a_read_i,
                                mem_a_write_i,
  input wire  [ADDR_WIDTH-1:0]  mem_a_addr_i,
  input wire  [DATA_WIDTH-1:0]  mem_a_data_i,
  output wire                   mem_a_valid_o,
  output wire [DATA_WIDTH-1:0]  mem_a_data_o,
  
  input wire  [USER_WIDTH-1:0]  mem_a_user_i,
  output wire [USER_WIDTH-1:0]  mem_a_user_o
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
  
  generate
    if (USE_BRAM == 1)
    begin: generate_bram
      W0RM_Peripheral_MemoryBlock_BRAM #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(MEM_DEPTH),
        .BASE_ADDR(BASE_ADDR),
        .INIT_FILE(INIT_FILE),
        .USER_WIDTH(USER_WIDTH)
      ) bram (
        .mem_clk(mem_clk),
        .cpu_reset(cpu_reset),
        
        .mem_a_valid_i(mem_a_valid_i),
        .mem_a_read_i(mem_a_read_i),
        .mem_a_write_i(mem_a_write_i),
        .mem_a_addr_i(mem_a_addr_i),
        .mem_a_data_i(mem_a_data_i),
        .mem_a_valid_o(mem_a_valid_o),
        .mem_a_data_o(mem_a_data_o),
        
        .mem_a_user_i(mem_a_user_i),
        .mem_a_user_o(mem_a_user_o)
      );
    end
    else
    begin : generate_rtl
      W0RM_Peripheral_MemoryBlock_RTL #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(MEM_DEPTH),
        .BASE_ADDR(BASE_ADDR),
        .INIT_FILE(INIT_FILE),
        .USER_WIDTH(USER_WIDTH)
      ) rtl (
        .mem_clk(mem_clk),
        .cpu_reset(cpu_reset),
        
        .mem_a_valid_i(mem_a_valid_i),
        .mem_a_read_i(mem_a_read_i),
        .mem_a_write_i(mem_a_write_i),
        .mem_a_addr_i(mem_a_addr_i),
        .mem_a_data_i(mem_a_data_i),
        .mem_a_valid_o(mem_a_valid_o),
        .mem_a_data_o(mem_a_data_o),
        
        .mem_a_user_i(mem_a_user_i),
        .mem_a_user_o(mem_a_user_o)
      );
    end
  endgenerate
endmodule
