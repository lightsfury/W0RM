`timescale 1ns/100ps

module W0RM_Demo(
  input wire      sysclk_p,
                  sysclk_n,
  input wire      cpu_reset,
  inout wire  [7:0] gpio_a,
  inout wire  [7:0] gpio_b,
  inout wire  [7:0] gpio_c,
  output wire       lcd_rs,
                    lcd_rw,
                    lcd_en,
  inout wire  [3:0] lcd_data
);
  localparam  INST_WIDTH  = 16;
  localparam  DATA_WIDTH  = 32;
  localparam  ADDR_WIDTH  = 32;
  
  wire  [ADDR_WIDTH-1:0]  inst_addr_o;
  wire  [DATA_WIDTH-1:0]  gpio_bus_data_i;
  wire                    gpio_bus_valid_i;
  
  wire  [ADDR_WIDTH-1:0]  mem_addr_o;
  wire  [DATA_WIDTH-1:0]  mem_data_o,
                          mem_data_i;
  
  wire  [DATA_WIDTH-1:0]  gpio_a_data_i;
  wire                    gpio_a_valid_i;
  wire  [DATA_WIDTH-1:0]  gpio_b_data_i;
  wire                    gpio_b_valid_i;
  wire  [DATA_WIDTH-1:0]  gpio_c_data_i;
  wire                    gpio_c_valid_i;
  wire  [DATA_WIDTH-1:0]  gpio_bc_data_i;
  wire                    gpio_bc_valid_i;
  wire  [DATA_WIDTH-1:0]  bus_data_i;
  wire                    bus_valid_i;
  
  wire  [ADDR_WIDTH-1:0]  inst_rom_1_addr_o,
                          inst_rom_2_addr_o,
                          inst_rom_3_addr_o,
                          inst_rom_4_addr_o,
                          inst_rom_addr_o;
  wire  [INST_WIDTH-1:0]  inst_rom_1_data_o,
                          inst_rom_2_data_o,
                          inst_rom_3_data_o,
                          inst_rom_4_data_o,
                          inst_rom_data_o;
  wire                    inst_rom_1_valid_o,
                          inst_rom_2_valid_o,
                          inst_rom_3_valid_o,
                          inst_rom_4_valid_o,
                          inst_rom_valid_o;
  
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
  
  W0RM_Peripheral_MemoryBlock #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(INST_WIDTH),
    .MEM_DEPTH(256),
    .BASE_ADDR(32'h2000_0000),
    .INIT_FILE("../demo/programs/boot-loader.hex"),
    .USER_WIDTH(ADDR_WIDTH),
    .USE_BRAM(0)
  ) boot_loader_rom (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_a_valid_i(inst_valid_o),
    .mem_a_read_i(1'b1),
    .mem_a_write_i(1'b0), // Not used
    .mem_a_addr_i(inst_addr_o),
    .mem_a_data_i(16'd0), // Not used
    .mem_a_valid_o(inst_rom_1_valid_o),
    .mem_a_data_o(inst_rom_1_data_o),
    .mem_a_user_i(inst_addr_o),
    .mem_a_user_o(inst_rom_1_addr_o)
  );
  
  W0RM_Peripheral_MemoryBlock #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(INST_WIDTH),
    .MEM_DEPTH(256),
    .BASE_ADDR(32'h2100_0000),
    .INIT_FILE("../demo/programs/blink-led.hex"),
    .USER_WIDTH(ADDR_WIDTH),
    .USE_BRAM(0)
  ) prog_0_rom (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_a_valid_i(inst_valid_o),
    .mem_a_read_i(1'b1),
    .mem_a_write_i(1'b0), // Not used
    .mem_a_addr_i(inst_addr_o),
    .mem_a_data_i(16'd0), // Not used
    .mem_a_valid_o(inst_rom_2_valid_o),
    .mem_a_data_o(inst_rom_2_data_o),
    .mem_a_user_i(inst_addr_o),
    .mem_a_user_o(inst_rom_2_addr_o)
  );
  
  W0RM_Peripheral_MemoryBlock #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(INST_WIDTH),
    .MEM_DEPTH(256),
    .BASE_ADDR(32'h2200_0000),
    .INIT_FILE("../demo/programs/switch-copy.hex"),
    .USER_WIDTH(ADDR_WIDTH),
    .USE_BRAM(0)
  ) prog_1_rom (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_a_valid_i(inst_valid_o),
    .mem_a_read_i(1'b1),
    .mem_a_write_i(1'b0), // Not used
    .mem_a_addr_i(inst_addr_o),
    .mem_a_data_i(16'd0), // Not used
    .mem_a_valid_o(inst_rom_3_valid_o),
    .mem_a_data_o(inst_rom_3_data_o),
    .mem_a_user_i(inst_addr_o),
    .mem_a_user_o(inst_rom_3_addr_o)
  );
  
  W0RM_Peripheral_MemoryBlock #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(INST_WIDTH),
    .MEM_DEPTH(256),
    .BASE_ADDR(32'h2300_0000),
    .INIT_FILE("../demo/programs/lcd-message.hex"),
    .USER_WIDTH(ADDR_WIDTH),
    .USE_BRAM(0)
  ) prog_2_rom (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_a_valid_i(inst_valid_o),
    .mem_a_read_i(1'b1),
    .mem_a_write_i(1'b0), // Not used
    .mem_a_addr_i(inst_addr_o),
    .mem_a_data_i(16'd0), // Not used
    .mem_a_valid_o(inst_rom_4_valid_o),
    .mem_a_data_o(inst_rom_4_data_o),
    .mem_a_user_i(inst_addr_o),
    .mem_a_user_o(inst_rom_4_addr_o)
  );
  
  W0RM_Peripheral_Bus_Extender_4port #(
    .DATA_WIDTH(ADDR_WIDTH + INST_WIDTH)
  ) bus_extender (
    .bus_clock(core_clk),
    
    .bus_port0_valid_i(inst_rom_1_valid_o),
    .bus_port0_data_i({inst_rom_1_data_o, inst_rom_1_addr_o}),
    
    .bus_port1_valid_i(inst_rom_2_valid_o),
    .bus_port1_data_i({inst_rom_2_data_o, inst_rom_2_addr_o}),
    
    .bus_port2_valid_i(inst_rom_3_valid_o),
    .bus_port2_data_i({inst_rom_3_data_o, inst_rom_3_addr_o}),
    
    .bus_port3_valid_i(inst_rom_4_valid_o),
    .bus_port3_data_i({inst_rom_4_data_o, inst_rom_4_addr_o}),
    
    .bus_valid_o(inst_rom_valid_o),
    .bus_data_o({inst_rom_data_o, inst_rom_addr_o})
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
    .inst_data_i(inst_rom_data_o),
    .inst_valid_i(inst_rom_valid_o),
    .inst_addr_i(inst_rom_addr_o),
    
    .mem_addr_o(mem_addr_o),
    .mem_data_o(mem_data_o),
    .mem_read_o(mem_read_o),
    .mem_write_o(mem_write_o),
    .mem_valid_o(mem_valid_o),
    .mem_data_i(bus_data_i),
    .mem_valid_i(bus_valid_i)
  );
  
  wire  [DATA_WIDTH-1:0]  bus_ext2_1_data;
  wire                    bus_ext2_1_valid;
  
  // Create a 3-device memory bus
  W0RM_Peripheral_Bus_Extender_4port bus_extender4_1(
    .bus_clock(core_clk),
    
    .bus_port0_valid_i(bus_ext2_1_valid),
    .bus_port0_data_i(bus_ext2_1_data),
    
    .bus_port1_valid_i(gpio_a_valid_i),
    .bus_port1_data_i(gpio_a_data_i),
    
    .bus_port2_valid_i(gpio_b_valid_i),
    .bus_port2_data_i(gpio_b_data_i),
    
    .bus_port3_valid_i(gpio_c_valid_i),
    .bus_port3_data_i(gpio_c_data_i),
    
    .bus_valid_o(bus_valid_i),
    .bus_data_o(bus_data_i)
  );
  
  W0RM_Peripheral_Bus_Extender bus_extender2_1(
    .bus_clock(core_clk),
    
    .bus_port0_valid_i(mem_valid_i),
    .bus_port0_data_i(mem_data_i),
    
    .bus_port1_valid_i(lcd_valid_i),
    .bus_port1_data_i(lcd_data_i),
    
    .bus_valid_o(bus_ext2_1_valid),
    .bus_data_o(bus_ext2_1_data)
  );
  
  /*
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
    
    .bus_port1_valid_i(gpio_bc_valid_i),
    .bus_port1_data_i(gpio_bc_data_i),
    
    .bus_valid_o(gpio_bus_valid_i),
    .bus_data_o(gpio_bus_data_i)
  );
  
  W0RM_Peripheral_Bus_Extender bus_extender3(
    .bus_clock(core_clk),
    
    .bus_port0_valid_i(gpio_b_valid_i),
    .bus_port0_data_i(gpio_b_data_i),
    
    .bus_port1_valid_i(gpio_c_valid_i),
    .bus_port1_data_i(gpio_c_data_i),
    
    .bus_valid_o(gpio_bc_valid_i),
    .bus_data_o(gpio_bc_data_i)
  ); // */
  
  W0RM_Peripheral_GPIO #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .GPIO_WIDTH(8),
    .BASE_ADDR(32'h8000_0000)
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
    .BASE_ADDR(32'h8000_0040)
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
  
  W0RM_Peripheral_GPIO #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .GPIO_WIDTH(8),
    .BASE_ADDR(32'h8000_0080)
  ) gpio_c_peripheral (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_valid_i(mem_valid_o),
    .mem_read_i(mem_read_o),
    .mem_write_i(mem_write_o),
    .mem_addr_i(mem_addr_o),
    .mem_data_i(mem_data_o),
    
    .mem_valid_o(gpio_c_valid_i),
    .mem_data_o(gpio_c_data_i),
    
    .pin_gpio_pad(gpio_c)
  );
  
  W0RM_Peripheral_MemoryBlock #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(1024),
    .USER_WIDTH(1),
    .BASE_ADDR(32'h4000_0000),
    .USE_BRAM(1)
  ) main_memory (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_a_valid_i(mem_valid_o),
    .mem_a_read_i(mem_read_o),
    .mem_a_write_i(mem_write_o),
    .mem_a_addr_i(mem_addr_o),
    .mem_a_data_i(mem_data_o),
    .mem_a_valid_o(mem_valid_i),
    .mem_a_data_o(mem_data_i),
    .mem_a_user_i(1'b0),
    .mem_a_user_o() // Not used
  );
  
  W0RM_Peripheral_CharLCD_4bit #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .BASE_ADDR(32'h8001_0000)
  ) character_lcd (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_valid_i(mem_valid_o),
    .mem_read_i(mem_read_o),
    .mem_write_i(mem_write_o),
    .mem_addr_i(mem_addr_o),
    .mem_data_i(mem_data_o),
    .mem_valid_o(lcd_valid_i),
    .mem_data_o(lcd_data_i),
    
    .lcd_bus_data_select(lcd_rs),
    .lcd_bus_read_write(lcd_rw),
    .lcd_bus_async_enable(lcd_en),
    .lcd_bus_data(lcd_data)
  );
endmodule
