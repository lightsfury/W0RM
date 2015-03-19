`timescale 1ns/100ps

module FileMemory #(
  parameter FILE_PATH   = "",
  parameter DATA_WIDTH  = 8,
  parameter ADDR_WIDTH  = 8,
  parameter MEM_DEPTH   = 16,
  parameter MEM_LATENCY = 0
)(
  input wire                    clk,
  
  input wire                    valid_i,
  input wire  [ADDR_WIDTH-1:0]  addr_i,
  
  output wire                   valid_o,
  output wire [DATA_WIDTH-1:0]  data_o
);
  function integer log2(input integer n);
	integer i, j;
    begin
      i = 1;
      j = 0;
      while (i < n)
      begin
        j = j + 1;
        i = i << 1;
      end
		log2 = j;
    end
  endfunction
  
  function integer pow2(input integer n);
  integer i, j;
    begin
      i = 0;
      j = 1;
      while (i < n)
      begin
        i = i + 1;
        j = j * 2;
      end
      pow2 = j;
    end
  endfunction
  
  //localparam NUM_LOCS   = pow2(ADDR_WIDTH);
  localparam DEPTH_BITS = log2(MEM_DEPTH);
  localparam ADDR_LOW   = (DATA_WIDTH / 8) - 1; //log2(DATA_WIDTH);
  localparam ADDR_HIGH  = DEPTH_BITS + ADDR_LOW;
  
  reg   [DATA_WIDTH-1:0]  mem [MEM_DEPTH:0];
  reg   [DATA_WIDTH-1:0]  data_r = 0;
  reg                     valid_r = 0;
  wire  [DEPTH_BITS-1:0]  addr_e = addr_i[ADDR_HIGH:ADDR_LOW];
  
  initial
  begin
    $readmemh(FILE_PATH, mem);
  end
  
  
  always @(posedge clk)
  begin
    if (valid_i)
    begin
      data_r <= mem[addr_e];
    end
    
    valid_r = valid_i;
  end
  
  // Delay portion
  generate
    if (MEM_LATENCY > 0)
    begin
      integer j;
      
      reg [DATA_WIDTH-1:0]  data_r1   [MEM_LATENCY:0];
      reg                   valid_r1  [MEM_LATENCY:0];
      
      initial
      begin
        for (j = 0; j < MEM_LATENCY; j = j + 1)
        begin
          data_r1[j] = {DATA_WIDTH{1'b0}};
          valid_r1[j] = 1'b0;
        end
      end
      
      genvar i;
      
      // First delay stage
      always @(posedge clk)
      begin
        data_r1[0] <= data_r;
        valid_r1[0] <= valid_r;
      end
      
      // Subsequent delay stages
      for (i = 1; i < MEM_LATENCY; i = i + 1)
      begin: for_latency
        
        always @(posedge clk)
        begin
          data_r1[i + 1]   <= data_r1[i];
          valid_r1[i + 1]  <= valid_r1[i];
        end
      end
        
      assign valid_o  = valid_r1[MEM_LATENCY];
      assign data_o   = data_r1[MEM_LATENCY];
    end
    else
    begin
      // No delay
      assign valid_o = valid_r;
      assign data_o = data_r;
    end
  endgenerate
endmodule
