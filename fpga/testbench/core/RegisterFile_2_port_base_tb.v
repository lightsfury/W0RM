`timescale 1ns/100ps

module RegisterFile_2_port_base_tb #(
  parameter DATA_WIDTH    = 8,
  parameter NUM_REGISTERS = 4,
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire done,
  output wire error
);
  // log base 2 function
  function integer log2(input integer n);
	integer i, j;
    begin
		i = 1;
		j = 0;
      //integer i = 1, j = 0;
      while (i < n)
      begin
        j = j + 1;
        i = i << 1;
      end
		log2 = j;
    end
  endfunction
  
  localparam ADDR_WIDTH     = log2(NUM_REGISTERS);
  localparam FS_DATA_WIDTH  = DATA_WIDTH + ADDR_WIDTH + 1;
  localparam FC_DATA_WIDTH  = 2 * (DATA_WIDTH + ADDR_WIDTH);
  
  reg                     clk = 0;
  reg                     go = 0;
  reg                     fc_go = 0;
  reg   [ADDR_WIDTH-1:0]  rd0_addr = 0,
                          rd1_addr = 1;
  wire  [DATA_WIDTH-1:0]  rd0_data,
                          rd1_data;
  wire  [ADDR_WIDTH-1:0]  wr_addr;
  wire  [DATA_WIDTH-1:0]  wr_data;
  wire                    wr_enable;
  wire                    fs_empty;
  wire                    fs_valid;
  reg   [ADDR_WIDTH-1:0]  rd0_addr_r1 = 0,
                          rd1_addr_r1 = 0;
  
  initial #50 go <= 1;
  
  always #2.5 clk <= ~clk;
  
  always @(posedge clk)
  begin
    if (go && fs_empty)
    begin
      // Move to confirm stage
      rd0_addr <= rd0_addr + 1;
      rd0_addr_r1 <= rd0_addr;
      rd1_addr <= rd1_addr + 1;
      rd1_addr_r1 <= rd1_addr;
      fc_go <= 1'b1;
    end
    
    if (fc_done)
    begin
      go <= 0;
      fc_go <= 0;
    end
  end
  
  FileSource #(
    .DATA_WIDTH(FS_DATA_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) write_data (
    .clk(clk),
    .ready(go),
    .valid(fs_valid),
    .empty(fs_empty),
    .data({wr_enable, wr_addr, wr_data})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) data_compare (
    .clk(clk),
    .valid(fc_go),
    .data({rd0_addr_r1, rd0_data, rd1_addr_r1, rd1_data}),
    .done(fc_done),
    .error(fc_error)
  );
  
  W0RM_Core_RegisterFile #(
    .SINGLE_CYCLE(1),
    .DATA_WIDTH(DATA_WIDTH),
    .NUM_REGISTERS(NUM_REGISTERS)
  ) dut (
    .clk(clk),
    // Read port 0
    .port_read0_addr(rd0_addr),
    .port_read0_data(rd0_data),
    // Read port 1
    .port_read1_addr(rd1_addr),
    .port_read1_data(rd1_data),
    // Write port
    .port_write_addr(wr_addr),
    .port_write_enable(wr_enable & fs_valid),
    .port_write_data(wr_data)
  );
  
  assign done   = fc_done;
  assign error  = fc_error;
endmodule
