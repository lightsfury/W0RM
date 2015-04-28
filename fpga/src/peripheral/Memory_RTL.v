`timescale 1ns/100ps

module W0RM_Peripheral_MemoryBlock_RTL #(
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

  localparam  MEM_ADDR_LOW    = log2(DATA_WIDTH / 8);
  localparam  MEM_ADDR_HIGH   = MEM_ADDR_LOW + log2(MEM_DEPTH);
  localparam  MEM_ADDR_WIDTH  = MEM_ADDR_HIGH - MEM_ADDR_LOW;
  
  localparam  MEM_ADDR_STOP   = BASE_ADDR + log2(MEM_DEPTH);
  
  reg   [DATA_WIDTH-1:0]  mem_contents [MEM_DEPTH-1:0];
  
  reg   [USER_WIDTH-1:0]  mem_a_user_r  = 0;
  reg                     mem_a_valid_r = 0;
  reg   [DATA_WIDTH-1:0]  mem_a_data_r  = 0;
  
  wire  [MEM_ADDR_WIDTH-1:0]  mem_a_addr_real = mem_a_addr_i[MEM_ADDR_HIGH:MEM_ADDR_LOW];
  wire                        mem_a_decode_ce = (mem_a_addr_i >= BASE_ADDR) && (mem_a_addr_i < MEM_ADDR_STOP);
  
  wire                        mem_a_ce = mem_a_valid_i && mem_a_decode_ce;
  reg   [MEM_ADDR_WIDTH-1:0]  mem_a_addr_r = 0;
  
  always @(posedge mem_clk)
  begin
    if (cpu_reset)
    begin
      mem_a_user_r  <= {USER_WIDTH{1'b0}};
      //mem_a_data_r  <= {DATA_WIDTH{1'b0}};
      mem_a_valid_r <= 1'b0;
    end
    
    if (mem_a_ce)
    begin
      mem_a_addr_r <= mem_a_addr_real;
      
      if (mem_a_write_i)
      begin
        mem_contents[mem_a_addr_real] <= mem_a_data_i;
      end
    end
    
    if (mem_a_ce)
    begin
      mem_a_user_r    <= mem_a_user_i;
    end
    
    mem_a_valid_r     <= mem_a_valid_i && mem_a_decode_ce && (mem_a_read_i || mem_a_write_i);
    /*
    begin
      if (mem_a_valid_i && mem_a_decode_ce)
      begin
        mem_a_data_r  <= mem_contents[mem_a_addr_real];
        if (mem_a_write_i)
        begin
          mem_contents[mem_a_addr_real] <= mem_a_data_i;
          mem_a_data_r                  <= mem_a_data_i;
        end
        
        mem_a_user_r    <= mem_a_user_i;
      end
      else
      begin
        mem_a_data_r    <= mem_a_data_r;
      end
    
      mem_a_valid_r     <= mem_a_valid_i && mem_a_decode_ce && (mem_a_read_i || mem_a_write_i);
    end // */
  end
  
  assign mem_a_user_o   = mem_a_user_r;
  assign mem_a_valid_o  = mem_a_valid_r;
  //assign mem_a_data_o   = mem_a_data_r;
  assign mem_a_data_o   = mem_contents[mem_a_addr_r];
  
  generate
    if (INIT_FILE == "")
    begin
      genvar i;
      for (i = 0; i < MEM_DEPTH; i = i + 1)
      begin: initialize_mem_zero
        initial
          mem_contents[i] = {USER_WIDTH{1'b0}};
      end
    end
    else
    begin
      initial
        $readmemh(INIT_FILE, mem_contents);
    end
  endgenerate
endmodule
