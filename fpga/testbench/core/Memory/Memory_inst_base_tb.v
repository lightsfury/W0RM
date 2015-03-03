`timescale 1n/100ps

module Memory_inst_base_tb #(
  parameter BLOCK_RAM     = 0,
  parameter BASE_ADDR     = 32'h20000000,
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire done,
              error
);
  localparam INST_WIDTH = 16;
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 32;
  
  localparam FS_WIDTH   = 5 + (2 * ADDR_WIDTH) + DATA_WIDTH;
  localparam FC_WIDTH   = INST_WIDTH;
  
  reg clk = 0;
  reg fs_go = 0;
  reg fs_pause = 1;
  reg first_run = 1;
  
  wire  [ADDR_WIDTH-1:0]  bus_addr;
  wire                    bus_read,
                          bus_write,
                          bus_valid_in;
  wire  [DATA_WIDTH-1:0]  bus_data_in,
                          bus_data_out;
  wire                    bus_valid_out;
  wire  [ADDR_WIDTH-1:0]  inst_addr;
  wire  [INST_WIDTH-1:0]  inst_data_out;
  
  always #2.5 clk <= ~clk;
  
  initial #50 fs_pause <= 1'b0;
  
  always @(posedge clk)
  begin
    if (fs_pause)
    begin
      fs_go <= 0;
    end
    else
    begin
      if (first_run)
      begin
        if (fs_go)
        begin
          fs_go <= 0;
          first_run <= 0;
        end
        else
        begin
          fs_go <= 1;
        end
      end
      else
      begin
        fs_go <= 1'b1;
      end
    end
  end
  
  FileSource #(
    .DATA_WIDTH(FS_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    
    .ready(fs_go),
    .valid(fs_valid_out),
    .empty(fs_empty),
    .data({bus_valid_in, inst_valid_in, bus_read, bus_write, inst_read, bus_addr, bus_data_in, inst_addr})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    
    .valid(inst_valid_out),
    .data(inst_data_out),
    .done(done),
    .error(error)
  );

  W0RM_CoreMemory #(
    .BLOCK_RAM(BLOCK_RAM),
    .BASE_ADDR(BASE_ADDR)
  ) dut (
    .clk(clk),
    
    .inst_addr(inst_addr),
    .inst_read(inst_read),
    .inst_valid_in(inst_valid_in && fs_valid_out),
    .inst_data_out(inst_data_out),
    .inst_valid_out(inst_valid_out),
    
    .bus_addr(bus_addr),
    .bus_read(bus_read),
    .bus_write(bus_write),
    .bus_valid_in(bus_valid_in && fs_valid_out),
    .bus_data_in(bus_data_in),
    .bus_data_out(bus_data_out),
    .bus_valid_out(bus_valid_out)
  );
endmodule
