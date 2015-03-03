`timescale 1ns/100ps

module W0RM_CoreMemory #(
  parameter BLOCK_RAM     = 0,
  parameter ADDR_WIDTH    = 32,
  parameter INST_WIDTH    = 16,
  parameter DATA_WIDTH    = 32,
  parameter BASE_ADDR     = 32'h20000000
)(
  input wire                      clk,
  
  input wire  [ADDR_WIDTH-1:0]    inst_addr,
  input wire                      inst_read,
                                  inst_valid_in,
  output wire [INST_WIDTH-1:0]    inst_data_out,
  output wire                     inst_valid_out,
  
  input wire  [ADDR_WIDTH-1:0]    bus_addr,
  input wire                      bus_read,
                                  bus_write,
                                  bus_valid_in,
  input wire  [DATA_WIDTH-1:0]    bus_data_in,
  output wire [DATA_WIDTH-1:0]    bus_data_out,
  output wire                     bus_valid_out
);
  localparam MEM_SIZE = 1024;
  
  reg   bus_valid_out_r   = 0,
        inst_valid_out_r  = 0;
  
  wire  [DATA_WIDTH-1:0]    bus_data_i;
  wire  [INST_WIDTH-1:0]    inst_data_i;
  wire  [10:0]              inst_addr_i     = inst_addr[11:1];
  wire  [9:0]               bus_addr_i      = bus_addr[11:2];
  wire                      bus_decode_ce   = (bus_addr >= BASE_ADDR)
                                           && (bus_addr < (BASE_ADDR + MEM_SIZE)),
                            inst_decode_ce  = (inst_addr >= BASE_ADDR)
                                           && (inst_addr < (BASE_ADDR + MEM_SIZE));
  
  assign bus_data_out   = bus_data_i;
  assign bus_valid_out  = bus_valid_out_r;
  assign inst_data_out  = inst_data_i;
  assign inst_valid_out = inst_valid_out_r;
  
  always @(posedge clk)
  begin
    if (bus_valid_in)
    begin
      bus_valid_out_r <= bus_read & bus_decode_ce;
    end
    else
    begin
      bus_valid_out_r <= 1'b0;
    end
    
    if (inst_valid_in)
    begin
      inst_valid_out_r <= inst_read & inst_decode_ce;
    end
    else
    begin
      inst_valid_out_r <= 1'b0;
    end
  end
  
  generate
    if (BLOCK_RAM == 1)
    begin
      W0RM_CoreRAM_Block block_mem (
        .clka(clk),
        .ena(inst_read & inst_valid_in & inst_decode_ce),
        .wea(1'b0), // Read-only port
        .addra(inst_addr_i),
        .dina(16'd0), // Read-only port
        .douta(inst_data_i),
        
        .clkb(clk),
        .enb((bus_read | bus_write) & bus_valid_in & bus_decode_ce),
        .web(bus_write & bus_valid_in & bus_decode_ce),
        .addrb(bus_addr_i),
        .dinb(bus_data_in),
        .doutb(bus_data_i)
      );
    end
    else
    begin
      wire  [DATA_WIDTH-1:0]  inst_data_i_32;
      reg   [10:0]            inst_addr_i_r = 0;
      
      always @(posedge clk)
        inst_addr_i_r <= inst_addr_i;
      
      W0RM_CoreRAM_Slice slice_mem (
        .clk(clk),
        .a(bus_addr_i),
        .we(bus_write & bus_valid_in & bus_decode_ce),
        .d(bus_data_in),
        .qspo(bus_data_i),
        
        .dpra(inst_addr_i[10:1]),
        .qdpo(inst_data_i_32)
      );
      
      assign inst_data_i = inst_addr_i_r[0] ? inst_data_i_32[15:0] : inst_data_i_32[31:16];
    end
  endgenerate
endmodule
