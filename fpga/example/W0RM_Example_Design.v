`timescale 1ns/100ps

module W0RM_Example_Design(
  input wire        sysclk,
  input wire        cpu_reset,
  output wire [7:0] leds
);
  localparam INST_WIDTH = 16;
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 32;
  wire  [INST_WIDTH-1:0]  inst_data_i;
  wire  [DATA_WIDTH-1:0]  inst_data;
  reg   [ADDR_WIDTH-1:0]  inst_addr_r = 0;
  reg                     inst_valid_i = 0;
  
  wire  [ADDR_WIDTH-1:0]  mem_addr_o;
  wire  [DATA_WIDTH-1:0]  mem_data_o,
                          mem_data_i;
  reg                     mem_valid_i = 0;

  IBUFG sysclk_bufg(
    .I(sysclk),
    .O(core_clk)
  );
  
  IBUF cpu_reset_input(
    .I(cpu_reset),
    .O(reset_i)
  );
  
  FDCPE reset_ff(
    .C(core_clk),
    .CE(1'b1),
    .PRE(1'b0),
    .CLR(1'b0),
    .D(reset_i),
    .Q(reset_r)
  );
  
  W0RM_Example_Design_Instruction_ROM example_rom(
    .clka(core_clk),
    .rsta(reset_r),
    
    .ena(inst_valid_o),
    .addra(inst_addr_o),
    
    .douta(inst_data)
  );
  
  always @(posedge core_clk)
  begin
    inst_valid_i  <= inst_valid_o;
    inst_addr_r   <= inst_addr_o;
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
    .SINGLE_CYCLE(0)
  ) w0rm (
    .core_clk(core_clk),
    .reset(reset_r),
    
    .inst_addr_o(inst_addr_o),
    .inst_valid_o(inst_valid_o),
    .inst_data_i(inst_data_i),
    .inst_valid_i(inst_valid_i),
    
    .mem_addr_o(mem_addr_o),
    .mem_data_o(mem_data_o),
    .mem_read_o(mem_read_o),
    .mem_write_o(mem_write_o),
    .mem_valid_o(mem_valid_o),
    .mem_data_i(mem_data_i),
    .mem_valid_i(mem_valid_i)
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

endmodule
