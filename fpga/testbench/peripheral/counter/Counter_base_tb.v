`timescale 1ns/100ps

module Counter_base_tb #(
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire done,
              error
);
  localparam  ADDR_WIDTH  = 8;
  localparam  DATA_WIDTH  = 8;
  localparam  TIME_WIDTH  = 8;
  
  reg       clk = 0,
            reset = 1;
  
  initial #11 reset = 0;
  
  always #2.5 clk <= ~clk;
  
  wire  [DATA_WIDTH-1:0]  mem_data_i,
                          mem_data_o;
  wire  [ADDR_WIDTH-1:0]  mem_addr_i;
  wire                    mem_valid_i,
                          mem_read_i,
                          mem_write_i,
                          mem_valid_o;
  wire  [TIME_WIDTH-1:0]  counter_value;
  
  assign counter_value = dut.timer;
  
  FileSource #(
    .DATA_WIDTH(3 + ADDR_WIDTH + DATA_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    .ready(~reset),
    .valid(fs_valid),
    .empty(fs_empty),
    .data({mem_valid_i, mem_read_i, mem_write_i, mem_addr_i, mem_data_i})
  );
  
  FileCompare #(
    .DATA_WIDTH(DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    .valid(mem_valid_o),
    .data(mem_data_o),
    .done(done),
    .error(error)
  );
  
  W0RM_Peripheral_Counter #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .TIME_WIDTH(TIME_WIDTH),
    .BASE_ADDR(8'h00)
  ) dut (
    .mem_clk(clk),
    .cpu_reset(reset),
    
    .mem_valid_i(mem_valid_i && fs_valid),
    .mem_read_i(mem_read_i),
    .mem_write_i(mem_write_i),
    .mem_addr_i(mem_addr_i),
    .mem_data_i(mem_data_i),
    
    .mem_valid_o(mem_valid_o),
    .mem_data_o(mem_data_o),
    
    .timer_reload(timer_reload)
  );
endmodule
