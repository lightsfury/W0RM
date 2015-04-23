`timescale 1ns/100ps

module W0RM_Demo(
  input wire      sysclk_p,
                  sysclk_n,
  input wire      cpu_reset,
  inout wire  [7:0] gpio_a,
  inout wire  [7:0] gpio_b
);
  localparam  INST_WIDTH  = 16;
  localparam  DATA_WIDTH  = 32;
  localparam  ADDR_WIDTH  = 32; 
  
  //wire  [INST_WIDTH-1:0]  inst_data_i;
  
  wire  [ADDR_WIDTH-1:0]  inst_addr_o;
  wire  [DATA_WIDTH-1:0]  inst_data;
  wire  [DATA_WIDTH-1:0]  gpio_bus_data_i;
  wire                    gpio_bus_valid_i;
  reg                     inst_valid_r1 = 0, 
                          inst_valid_r2 = 0;
  reg   [ADDR_WIDTH-1:0]  inst_addr_r1  = 0,
                          inst_addr_r2  = 0;
  reg   [INST_WIDTH-1:0]  inst_data_r   = 0;
  
  wire  [ADDR_WIDTH-1:0]  mem_addr_o;
  wire  [DATA_WIDTH-1:0]  mem_data_o,
                          mem_data_i;
  reg                     mem_valid_i = 0;
  
  wire  [DATA_WIDTH-1:0]  gpio_a_data_i;
  wire                    gpio_a_valid_i;
  wire  [DATA_WIDTH-1:0]  gpio_b_data_i;
  wire                    gpio_b_valid_i;
  wire  [DATA_WIDTH-1:0]  bus_data_i;
  wire                    bus_valid_i;
  
  IBUFGDS sysclk_buffer(
    .I(sysclk_p),
    .IB(sysclk_n),
    .O(sysclk)
  );
  
  W0RM_Example_PLL w0rm_demo_pll (
    .CLKIN1_IN(sysclk),
    .RST_IN(1'b0),
    .CLK0_OUT(core_clk),
    .LOCKED_OUT(pll_locked)
  );
  
  IBUF cpu_reset_input(
    .I(cpu_reset),
    .O(reset_i)
  );
  
  reg reset_r = 1;
  always @(posedge core_clk)
    reset_r <= ~reset_i || ~pll_locked;
  
  always @(posedge core_clk)
  begin
    inst_valid_r2 <= inst_valid_r1;
    inst_valid_r1 <= inst_valid_o;
    
    inst_addr_r2  <= inst_addr_r1;
    inst_addr_r1  <= inst_addr_o;
    
    if (inst_addr_r1[1])
      inst_data_r <= inst_data[INST_WIDTH-1:0];
    else
      inst_data_r <= inst_data[DATA_WIDTH-1:(DATA_WIDTH-INST_WIDTH)];
  end
  
  W0RM_Example_Design_Instruction_ROM example_rom(
    .clka(core_clk),
    .rsta(reset_r),
    
    .ena(1'b1),
    .addra(inst_addr_o),
    
    .douta(inst_data)
  );
  
  // W0RM CPU core
  W0RM_TopLevel #(
    .INST_CACHE(0),
    .SINGLE_CYCLE(1)
  ) w0rm (
    .core_clk(core_clk),
    .reset(reset_r),
    
    .inst_addr_o(inst_addr_o),
    .inst_valid_o(inst_valid_o),
    .inst_data_i(inst_data_r),
    .inst_valid_i(inst_valid_r2),
    .inst_addr_i(inst_addr_r2),
    
    .mem_addr_o(mem_addr_o),
    .mem_data_o(mem_data_o),
    .mem_read_o(mem_read_o),
    .mem_write_o(mem_write_o),
    .mem_valid_o(mem_valid_o),
    .mem_data_i(bus_data_i),
    .mem_valid_i(bus_valid_i)
  );
  
  // Create a 3-device memory bus
  W0RM_Peripheral_Bus_Extender bus_extender1(
    .bus_clock(core_clk),
    
    .bus_port0_valid_i(gpio_bus_valid_i),
    .bus_port0_data_i(gpio_bus_data_i),
    
    .bus_port1_valid_i(mem_valid_i),
    .bus_port1_data_i(mem_data_i),
    
    .bus_valid_o(bus_valid_i),
    .bus_data_o(bus_data_i)
  );
  
  W0RM_Peripheral_Bus_Extender bus_extender2(
    .bus_clock(core_clk),
    
    .bus_port0_valid_i(gpio_a_valid_i),
    .bus_port0_data_i(gpio_a_data_i),
    
    .bus_port1_valid_i(gpio_b_valid_i),
    .bus_port1_data_i(gpio_b_data_i),
    
    .bus_valid_o(gpio_bus_valid_i),
    .bus_data_o(gpio_bus_data_i)
  );
  
  W0RM_Peripheral_GPIO #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .GPIO_WIDTH(8),
    .BASE_ADDR(32'h80000040)
  ) gpio_a_peripheral (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_valid_i(mem_valid_o),
    .mem_read_i(mem_read_o),
    .mem_write_i(mem_write_o),
    .mem_addr_i(mem_addr_o),
    .mem_data_i(mem_data_o),
    
    .mem_valid_o(gpio_a_valid_i),
    .mem_data_o(gpio_a_data_i),
    
    .pin_gpio_pad(gpio_a)
  );
  
  W0RM_Peripheral_GPIO #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .GPIO_WIDTH(8),
    .BASE_ADDR(32'h80000080)
  ) gpio_b_peripheral (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_valid_i(mem_valid_o),
    .mem_read_i(mem_read_o),
    .mem_write_i(mem_write_o),
    .mem_addr_i(mem_addr_o),
    .mem_data_i(mem_data_o),
    
    .mem_valid_o(gpio_b_valid_i),
    .mem_data_o(gpio_b_data_i),
    
    .pin_gpio_pad(gpio_b)
  );
  
  W0RM_CoreRAM_Block main_memory(
    // Port A is not used in this example
    .clka(1'b0),
    .ena(1'b0),
    .wea(1'b0),
    .addra(11'd0),
    .dina(16'd0),
    .douta(), // Not used
    
    .clkb(core_clk),
    .enb(mem_valid_o && (mem_read_o || mem_write_o)),
    .web(mem_valid_o && mem_write_o),
    .addrb(mem_addr_o[11:2]),
    .dinb(mem_data_o),
    .doutb(mem_data_i)
  );
endmodule
