`timescale 1ns/100ps

module LCD_base_tb #(
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire done,
              error
);
  localparam  ADDR_WIDTH  = 8;
  localparam  DATA_WIDTH  = 8;
  localparam  FS_DATA_WIDTH = 3 + ADDR_WIDTH + DATA_WIDTH;
  localparam  FC_DATA_WIDTH = 2 + 4;
  
  reg   clk = 0;
  reg   reset = 1;
  
  wire  [DATA_WIDTH-1:0]  mem_data_i,
                          mem_data_o;
  wire  [ADDR_WIDTH-1:0]  mem_addr_i;
  wire                    mem_valid_i,
                          mem_valid_o,
                          mem_read_i,
                          mem_write_i;
  wire                    lcd_rs,
                          lcd_rw,
                          lcd_en;
  wire  [3:0]             lcd_data;
  
  always #5 clk <= ~clk;
  
  initial #11 reset = 0;
  
  FileSource #(
    .DATA_WIDTH(FS_DATA_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    .ready(~reset),
    .valid(fs_valid),
    .empty(fs_empty),
    .data({mem_valid_i, mem_read_i, mem_write_i, mem_addr_i, mem_data_i})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(~lcd_en),
    .valid(1'b1),
    .data({lcd_rs, lcd_rw, lcd_data}),
    .done(done),
    .error(error)
  );

  W0RM_Peripheral_CharLCD_4bit #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .BASE_ADDR(8'd0)
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
    
    .lcd_bus_data_select(lcd_rs),
    .lcd_bus_read_write(lcd_rw),
    .lcd_bus_async_enable(lcd_en),
    .lcd_bus_data(lcd_data)
  );
endmodule
