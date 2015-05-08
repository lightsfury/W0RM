`timescale 1ns/100ps

module W0RM_Peripheral_DVI_Output #(
  parameter MAX_H_PIXELS  = 1920,
  parameter MAX_V_PIXELS  = 1080,
  parameter COLOR_WIDTH   = 24,
  parameter BUS_WIDTH     = 12,
  parameter DATA_WIDTH    = 32,
  parameter ADDR_WIDTH    = 32,
  parameter SYSCLK_PERIOD = 5.0,
  parameter BASE_ADDR     = 32'h9000_0000
)(
  input wire                    sys_clk,
  input wire                    mem_clk,
  input wire                    cpu_reset,
  
  // Port A
  input wire                    mem_valid_i,
                                mem_read_i,
                                mem_write_i,
  input wire  [ADDR_WIDTH-1:0]  mem_addr_i,
  input wire  [DATA_WIDTH-1:0]  mem_data_i,
  output wire                   mem_valid_o,
  output wire [DATA_WIDTH-1:0]  mem_data_o,
  
  output wire [BUS_WIDTH-1:0]   dvi_data,
  output wire                   dvi_data_valid,
                                dvi_h_sync,
                                dvi_v_sync,
                                dvi_clk_p,
                                dvi_clk_n
);
  wire  [COLOR_WIDTH-1:0] pixel_color;
  wire  [BUS_WIDTH-1:0]   pixel_data_1,
                          pixel_data_2;
  
  W0RM_Peripheral_MemoryBlock_RTL_DualPort #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(24),
    .MEM_DEPTH(MAX_H_PIXELS * MAX_V_PIXELS)
  ) mem_tdp_rtl (
    .mem_a_clk(mem_clk),
    .mem_a_valid_i(mem_valid_i),
    .mem_a_write_i(mem_write_i),
    .mem_a_addr_i(mem_addr_i),
    .mem_a_data_i(mem_data_i[24:0]),
    .mem_a_valid_o(mem_a_valid_o),
    .mem_a_data_o(mem_a_data_o),
    
    .mem_b_clk(dvi_clk),
    .mem_b_valid_i(mem_b_valid_i),
    .mem_b_write_i(mem_b_write_i),
    .mem_b_addr_i(mem_b_addr_i),
    .mem_b_data_i(mem_b_data_i),
    .mem_b_valid_o(mem_b_valid_o),
    .mem_b_data_o(mem_b_data_o)
  );
  
  OBUFDS dvi_clk_buffer(
    .I(dvi_clk),
    .O(dvi_clk_p),
    .OB(dvi_clk_n)
  );
  
  genvar i;
  generate
    assign pixel_data_1 = pixel_color[BUS_WIDTH-1:0];
    for (i = 0; i < BUS_WIDTH; i = i + 1)
    begin: gen_bus_data
      if ((BUS_WIDTH + i) >= COLOR_WIDTH)
        assign pixel_data_2[i] = 1'b0;
      else
        assign pixel_data_2[i] = pixel_color[BUS_WIDTH + i];
    
      ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
      ) ddr_pin (
        .C(dvi_clk), // clk
        .CE(dvi_output_enable), // clk enable
        .D1(pixel_data_1[i]),
        .D2(pixel_data_2[i]),
        .R(dvi_output_reset),
        .S(dvi_output_set),
        .Q(dvi_data[i])
      );
    end
  endgenerate
endmodule
