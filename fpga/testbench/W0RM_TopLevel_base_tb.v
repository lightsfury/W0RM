`timescale 1ns/100ps

module W0RM_TopLevel_base_tb #(
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire done,
              error
);
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 32;
  
  reg clk = 0, reset = 1;
  reg inst_valid_r = 0;
  
  wire  [DATA_WIDTH-1:0]  mem_data_o,
                          mem_data_i;
  wire  [ADDR_WIDTH-1:0]  mem_addr_o;
  wire                    mem_read_o,
                          mem_write_o,
                          mem_valid_o;
  reg                     mem_valid_i = 0;
  
  initial #11 reset = 0;
  
  always #2.5 clk <= ~clk;
  
  wire  [15:0]  inst_data;
  
  FileSource #(
    .DATA_WIDTH(16),
    .FILE_PATH(FILE_SOURCE)
  ) inst_source (
    .clk(clk),
    
    .ready(inst_req_valid),
    .valid(inst_valid),
    .empty(),
    .data(inst_data)
  );
  
  FileCompare #(
    .DATA_WIDTH(2 + (2 * DATA_WIDTH)),
    .FILE_PATH(FILE_COMPARE)
  ) mem_compare (
    .clk(clk),
    
    .valid(mem_valid_o),
    .data({mem_read_o, mem_write_o, mem_addr_o, mem_data_o}),
    .done(done),
    .error(error)
  );
  
  W0RM_TopLevel #(
    .SINGLE_CYCLE(0),
    .INST_CACHE(0)
  ) dut (
    .core_clk(clk),
    .reset(reset),
    
    // Instruction port
    .inst_addr_o(), // Not used
    .inst_valid_o(inst_req_valid),
    .inst_data_i(inst_data),
    .inst_valid_i(inst_valid),
    
    // Data port
    .mem_addr_o(mem_addr_o),
    .mem_data_o(mem_data_o),
    .mem_read_o(mem_read_o),
    .mem_write_o(mem_write_o),
    .mem_valid_o(mem_valid_o),
    .mem_data_i(mem_data_i),
    .mem_valid_i(mem_valid_i)
  );
  
  // Memory fixture
  W0RM_CoreRAM_Block mem_fixture(
    .clka(clk),
    .clkb(clk),
    
    .enb(mem_valid_o && (mem_write_o || mem_read_o)),
    .web(mem_valid_o && mem_write_o),
    .addrb(mem_addr_o[11:2]),
    .dinb(mem_data_o),
    .doutb(mem_data_i),
    
    // Port A is not in use
    .ena(1'b0),
    .wea(1'b0),
    .addra(11'd0),
    .dina(16'd0),
    .douta()
  );
  
  always @(posedge clk)
  begin
    mem_valid_i <= mem_valid_o;
  end
endmodule
