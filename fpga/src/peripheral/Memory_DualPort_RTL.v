`timescale 1ns/100ps

module W0RM_Peripheral_MemoryBlock_RTL_DualPort #(
  parameter ADDR_WIDTH    = 32,
  parameter DATA_WIDTH    = 32,
  parameter MEM_DEPTH     = 1024,
  parameter USE_INIT_FILE = 0,
  parameter INIT_FILE     = ""
)(
  // Port A
  input wire                    mem_a_clk,
  input wire                    mem_a_valid_i,
                                mem_a_write_i,
  input wire  [ADDR_WIDTH-1:0]  mem_a_addr_i,
  input wire  [DATA_WIDTH-1:0]  mem_a_data_i,
  output wire                   mem_a_valid_o,
  output wire [DATA_WIDTH-1:0]  mem_a_data_o,
  // Port B
  input wire                    mem_b_clk,
  input wire                    mem_b_valid_i,
                                mem_b_write_i,
  input wire  [ADDR_WIDTH-1:0]  mem_b_addr_i,
  input wire  [DATA_WIDTH-1:0]  mem_b_data_i,
  output wire                   mem_b_valid_o,
  output wire [DATA_WIDTH-1:0]  mem_b_data_o
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
  
  localparam  MEM_ADDR_LOW  = log2(DATA_WIDTH / 8);
  localparam  MEM_ADDR_HIGH = log2(MEM_DEPTH) + MEM_ADDR_LOW;

  reg   [DATA_WIDTH-1:0]  mem_rtl_tdp [MEM_DEPTH-1:0];
  reg   [DATA_WIDTH-1:0]  mem_a_data_r  = 0,
                          mem_b_data_r  = 0;
  reg                     mem_a_valid_r = 0,
                          mem_b_valid_r = 0;
  
  assign  mem_a_data_o  = mem_a_data_r;
  assign  mem_a_valid_o = mem_a_valid_r;
  assign  mem_b_data_o  = mem_b_data_r;
  assign  mem_b_valid_o = mem_b_valid_r;
  
  generate
    if (USE_INIT_FILE)
      initial
        $readmemh(INIT_FILE, mem_rtl_tdp, 0, MEM_DEPTH - 1);
  endgenerate
  
  always @(posedge mem_a_clk)
  begin
    if (mem_a_valid_i)
    begin
      if (mem_a_write_i)
        mem_rtl_tdp[mem_a_addr_i[MEM_ADDR_HIGH:MEM_ADDR_LOW]] <= mem_a_data_i;
      mem_a_data_r  <= mem_rtl_tdp[mem_a_addr_i[MEM_ADDR_HIGH:MEM_ADDR_LOW]];
    end
    mem_a_valid_r <= mem_a_valid_i;
  end
  
  always @(posedge mem_b_clk)
  begin
    if (mem_b_valid_i)
    begin
      if (mem_b_write_i)
        mem_rtl_tdp[mem_b_addr_i[MEM_ADDR_HIGH:MEM_ADDR_LOW]] <= mem_b_data_i;
      mem_b_data_r  <= mem_rtl_tdp[mem_b_addr_i[MEM_ADDR_HIGH:MEM_ADDR_LOW]];
    end
    mem_b_valid_r <= mem_b_valid_i;
  end
endmodule
