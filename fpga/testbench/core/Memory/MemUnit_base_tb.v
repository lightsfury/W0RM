`timescale 1ns/100ps

module MemUnit_base_tb #(
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire done,
              error
);
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 32;
  
  reg clk = 0;
  reg bus_valid_i = 0;
  wire  [DATA_WIDTH-1:0]  bus_data_i,
                          bus_data_o,
                          mem_data,
                          mem_result;
  wire  [ADDR_WIDTH-1:0]  bus_addr_o,
                          mem_addr;
  reg                     mem_ready_r = 0;
  
  always #2.5 clk <= ~clk;
  
  always @(posedge clk)
  begin
    mem_ready_r <= mem_ready;
  end
  
  FileSource #(
    .DATA_WIDTH(4 + DATA_WIDTH + ADDR_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    
    .ready(mem_ready && mem_ready_r),
    .valid(fs_valid),
    .empty(),
    .data({
      mem_valid,
      mem_read,
      mem_write,
      mem_is_pop,
      mem_data,
      mem_addr
    })
  );
  
  FileCompare #(
    .DATA_WIDTH(DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    
    .valid(mem_valid_o),
    .data(mem_result),
    .done(done),
    .error(error)
  );

  W0RM_Core_Memory #(
    .USER_WIDTH(1)
  ) dut (
    .clk(clk),
    
    .mem_ready(mem_ready),
    .mem_output_valid(mem_valid_o),
    .mem_data_out(mem_result),
    
    .mem_write(mem_write),
    .mem_read(mem_read),
    .mem_is_pop(mem_is_pop),
    .mem_data(mem_data),
    .mem_addr(mem_addr),
    .mem_valid_i(mem_valid && fs_valid),
    
    .data_bus_write_out(bus_write_o),
    .data_bus_read_out(bus_read_o),
    .data_bus_valid_out(bus_valid_o),
    .data_bus_addr_out(bus_addr_o),
    .data_bus_data_out(bus_data_o),
    
    .data_bus_data_in(bus_data_i),
    .data_bus_valid_in(bus_valid_i),
    
    .user_data_in(1'b0),
    .user_data_out() // Not used
  );
  
  // Memory fixture
  W0RM_CoreRAM_Block mem_fixture(
    .clka(clk),
    .clkb(clk),
    
    .enb(bus_valid_o && (bus_write_o || bus_read_o)),
    .web(bus_valid_o && bus_write_o),
    .addrb(bus_addr_o[11:2]),
    .dinb(bus_data_o),
    .doutb(bus_data_i),
    
    // Port A is not in use
    .ena(1'b0),
    .wea(1'b0),
    .addra(11'd0),
    .dina(16'd0),
    .douta()
  );
  
  always @(posedge clk)
    bus_valid_i <= bus_valid_o;
endmodule
