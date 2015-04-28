`timescale 1ns/100ps

module W0RM_Peripheral_MemoryBlock_BRAM #(
  parameter ADDR_WIDTH  = 32,
  parameter DATA_WIDTH  = 32,
  parameter MEM_DEPTH   = 512,
  parameter BASE_ADDR   = 32'h4000_0000,
  parameter INIT_FILE   = "",
  parameter USER_WIDTH  = 32
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



  localparam  WE_WIDTH        = (DATA_WIDTH >= 37) ? 8 :
                                (DATA_WIDTH >= 19) ? 4 :
                                (DATA_WIDTH >= 10) ? 2 : 1;
  localparam  MEM_WIDTH       = (DATA_WIDTH >= 37) ? 72 : 
                                (DATA_WIDTH >= 19) ? 36 :
                                (DATA_WIDTH >= 10) ? 18 : 9;
  
  localparam  MEM_ADDR_START  = BASE_ADDR;
  localparam  MEM_ADDR_STOP   = BASE_ADDR + MEM_DEPTH;
  localparam  MEM_LOW         = log2(DATA_WIDTH / 8);
  //localparam  MEM_HIGH        = log2(MEM_DEPTH) + MEM_LOW;
  //localparam  MEM_ADDR_INT_W  = log2(MEM_DEPTH);
  localparam  BRAM_SIZE       = ((DATA_WIDTH * MEM_DEPTH) >= (18 * 1024)) ? "36Kb" : "18Kb";
  localparam  BRAM_REAL_DEPTH = (BRAM_SIZE == "18Kb") ? (18 * 1024) : (36 * 1024);
  localparam  ADDR_REAL_WIDTH = log2(BRAM_REAL_DEPTH / MEM_WIDTH) - 1;
  localparam  MEM_HIGH        = ADDR_REAL_WIDTH + MEM_LOW;
  
  wire  mem_a_decode_ce = (mem_a_addr_i >= BASE_ADDR) && (mem_a_addr_i < MEM_ADDR_STOP);
  wire  [ADDR_REAL_WIDTH:0] mem_a_addr_int  = mem_a_addr_i[MEM_HIGH:MEM_LOW];
  
  reg                       mem_a_valid_r = 0;
  reg   [USER_WIDTH-1:0]    mem_a_user_r  = 0;
  
  BRAM_SINGLE_MACRO #(
    .BRAM_SIZE(BRAM_SIZE),
    .DEVICE("VIRTEX5"),
    .DO_REG(0),
    .INIT({DATA_WIDTH{1'b0}}),
    .INIT_FILE(INIT_FILE),
    .WRITE_WIDTH(DATA_WIDTH),
    .READ_WIDTH(DATA_WIDTH),
    .SIM_MODE("SAFE"),
    .SRVAL({DATA_WIDTH{1'b0}}),
    .WRITE_MODE("WRITE_FIRST")
  ) mem_contents (
    .CLK(mem_clk),
    .RST(cpu_reset),
    .REGCE(1'b0),
    
    .ADDR(mem_a_addr_int),
    .WE({WE_WIDTH{mem_a_write_i}}),
    .EN(mem_a_decode_ce && mem_a_valid_i && (mem_a_write_i || mem_a_read_i)),
    .DI(mem_a_data_i),
    .DO(mem_a_data_o)
  );
  
  assign mem_a_user_o   = mem_a_user_r;
  assign mem_a_valid_o  = mem_a_valid_r;
  
  always @(posedge mem_clk)
  begin
    if (mem_a_valid_i && mem_a_decode_ce)
    begin
      mem_a_user_r  <= mem_a_user_i;
    end
    else
    begin
      mem_a_user_r  <= {USER_WIDTH{1'b0}};
    end
    
    mem_a_valid_r   <= mem_a_valid_i && mem_a_decode_ce && (mem_a_read_i || mem_a_write_i);
  end
endmodule
