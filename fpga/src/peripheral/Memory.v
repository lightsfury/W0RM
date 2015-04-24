`timescale 1ns/100ps

module W0RM_Peripheral_MemoryBlock #(
  parameter ADDR_WIDTH  = 32,
  parameter DATA_WIDTH  = 32,
  parameter MEM_DEPTH   = 512,
  parameter BASE_ADDR   = 32'h4000_0000,
  parameter INIT_FILE   = "",
  parameter USER_WIDTH  = 32
)(
  input wire                    mem_clk,
  
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
  
  localparam  MEM_ADDR_START  = BASE_ADDR;
  localparam  MEM_ADDR_STOP   = BASE_ADDR + MEM_DEPTH;
  localparam  MEM_LOW         = log2(DATA_WIDTH / 8);
  localparam  MEM_HIGH        = log2(MEM_DEPTH) + MEM_LOW;
  localparam  MEM_ADDR_INT_W  = log2(MEM_DEPTH);
  
  reg [DATA_WIDTH-1:0]  mem_contents  [MEM_DEPTH:0];
  
  wire  mem_a_decode_ce = (mem_a_addr_i >= BASE_ADDR) && (mem_a_addr_i < MEM_ADDR_STOP);
  wire  [MEM_ADDR_INT_W:0]  mem_a_addr_int  = mem_a_addr_i[MEM_HIGH:MEM_LOW];
  
  reg                       mem_a_valid_r = 0;
  reg   [MEM_ADDR_INT_W:0]  mem_a_addr_r  = 0;
  reg   [USER_WIDTH-1:0]    mem_a_user_r  = 0;
  
  assign mem_a_user_o   = mem_a_user_r;
  assign mem_a_valid_o  = mem_a_valid_r;
  assign mem_a_data_o   = mem_contents[mem_a_addr_r];
  
  genvar i;
  generate
    if (INIT_FILE == "")
    begin
      for (i = 0; i < MEM_DEPTH; i = i + 1)
      begin: mem_contents_init
        initial
          mem_contents[i] = {DATA_WIDTH{1'b0}};
      end
    end
    else
    begin
      for (i = 0; i < MEM_DEPTH; i = i + 1)
      begin: mem_contents_init
        initial
          mem_contents[i] = {DATA_WIDTH{1'b0}};
      end
      initial
      begin
        $display("Reading memory contents from '%s'.", INIT_FILE);
        $readmemh(INIT_FILE, mem_contents);
      end
    end
  endgenerate
  
  always @(posedge mem_clk)
  begin
    if (mem_a_valid_i && mem_a_decode_ce)
    begin
      mem_a_addr_r <= mem_a_addr_int;
      if (mem_a_write_i)
      begin
        mem_contents[mem_a_addr_int] <= mem_a_data_i;
      end
      mem_a_user_r <= mem_a_user_i;
    end
    
    mem_a_valid_r <= mem_a_valid_i && mem_a_decode_ce && (mem_a_read_i || mem_a_write_i);
  end
endmodule
