`timescale 1ns/100ps

module W0RM_Example_Design(
  input wire        sysclk_p,
                    sysclk_n,
  input wire        cpu_reset,
  inout wire  [7:0] leds
);
  localparam INST_WIDTH = 16;
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 32;
  wire  [INST_WIDTH-1:0]  inst_data_i;
  wire  [DATA_WIDTH-1:0]  inst_data;
  wire  [ADDR_WIDTH-1:0]  inst_addr_o;
  reg   [ADDR_WIDTH-1:0]  inst_addr_r = 0;
  //reg                     inst_valid_i = 0;
  
  wire  [ADDR_WIDTH-1:0]  mem_addr_o;
  wire  [DATA_WIDTH-1:0]  mem_data_o,
                          mem_data_i;
  reg                     mem_valid_i = 0;
  wire  [DATA_WIDTH-1:0]  gpio_data_i;
  wire                    gpio_valid_i;
  wire  [DATA_WIDTH-1:0]  bus_data_i;
  wire                    bus_valid_i;
  //reg   [INST_WIDTH-1:0]  inst_data_r = 0;
  wire                    sysclk;
  
  IBUFGDS sysclk_buffer(
    .I(sysclk_p),
    .IB(sysclk_n),
    .O(sysclk)
  );
  
  // Instantiate the module
  W0RM_Example_PLL w0rm_example_pll (
    .CLKIN1_IN(sysclk),
    .RST_IN(1'b0),
    .CLK0_OUT(core_clk),
    .LOCKED_OUT(pll_locked)
  );

  /*
  IBUFG sysclk_bufg(
    .I(sysclk),
    .O(core_clk)
  ); // */
  
  IBUF cpu_reset_input(
    .I(cpu_reset),
    .O(reset_i)
  );
  
  reg reset_r = 1;
  always @(posedge core_clk)
    reset_r <= ~reset_i || ~pll_locked;
  
  W0RM_Example_Design_Instruction_ROM example_rom(
    .clka(core_clk),
    .rsta(reset_r),
    
    .ena(inst_valid_o),
    .addra(inst_addr_o),
    
    .douta(inst_data)
  );
  
  reg                     inst_valid_r1 = 0, 
                          inst_valid_r2 = 0;
  reg   [ADDR_WIDTH-1:0]  inst_addr_r1  = 0,
                          inst_addr_r2  = 0;
  reg   [INST_WIDTH-1:0]  inst_data_r   = 0;
              
  
  always @(posedge core_clk)
  begin
    inst_valid_r1 <= inst_valid_o;
    inst_valid_r2 <= inst_valid_r1;
    
    inst_addr_r1  <= inst_addr_o;
    inst_addr_r2  <= inst_addr_r1;
    
    if (inst_addr_r1[1])
      inst_data_r <= inst_data[INST_WIDTH-1:0];
    else
      inst_data_r <= inst_data[DATA_WIDTH-1:(DATA_WIDTH-INST_WIDTH)];
  end
  
  /*
  always @(*)
  begin
    if (inst_addr_r[1])
    begin
      inst_data_i = inst_data[INST_WIDTH-1:0];
    end
    else
    begin
      inst_data_i = inst_data[DATA_WIDTH-1 : DATA_WIDTH-INST_WIDTH];
    end
  end // */
  
  //*
  // Mux between the high/low part of inst_data
  assign inst_data_i = (inst_addr_r[1])
                      ? (inst_data[INST_WIDTH-1:0])
                      : (inst_data[DATA_WIDTH-1: DATA_WIDTH-INST_WIDTH]);
  // */

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
  
  //! @todo Until I make a "smart" memory wrapper, the core memory should be the
  //! "low priority" device
  W0RM_Peripheral_Bus_Extender bus_extender(
    .bus_clock(core_clk),
    
    .bus_port1_valid_i(mem_valid_i),
    .bus_port1_data_i(mem_data_i),
    
    .bus_port0_valid_i(gpio_valid_i),
    .bus_port0_data_i(gpio_data_i),
    
    .bus_valid_o(bus_valid_i),
    .bus_data_o(bus_data_i)
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
  
  always @(posedge core_clk)
    mem_valid_i <= mem_valid_o;
  
  W0RM_Peripheral_GPIO #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .GPIO_WIDTH(8),
    .BASE_ADDR(32'h80000080)
  ) gpio_a (
    .mem_clk(core_clk),
    .cpu_reset(reset_r),
    
    .mem_valid_i(mem_valid_o),
    .mem_read_i(mem_read_o),
    .mem_write_i(mem_write_o),
    .mem_addr_i(mem_addr_o),
    .mem_data_i(mem_data_o),
    
    .mem_valid_o(gpio_valid_i),
    .mem_data_o(gpio_data_i),
    
    .pin_gpio_pad(leds)
  );
endmodule
