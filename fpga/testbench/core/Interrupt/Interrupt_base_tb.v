`timescale 1ns/100ps

module Interupt_base_tb #(
  parameter FILE_SOURCE   = "",
  parameter FILE_COMPARE  = ""
)(
  output wire done,
              error
);
  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 8;
  localparam ISR_WIDTH  = 4;
  localparam FS_DATA_WIDTH  = 3 + ISR_WIDTH + (5 * DATA_WIDTH);
  localparam FC_DATA_WIDTH  = (5 * DATA_WIDTH);
  
  reg clk = 0;
  reg reset = 1;
  
  always #2.5 clk <= ~clk;
  
  initial #11 reset = 0;
  
  wire          inst_valid_in;
  wire  [15:0]  inst_data_in;
  
  wire          inst_valid_out;
  wire  [15:0]  inst_data_out;
  
  wire          inst_addr_valid;
  wire  [31:0]  inst_addr;
  
  FileSource #(
    .DATA_WIDTH(FS_DATA_WIDTH),
    .FILE_PATH(FILE_SOURCE)
  ) source (
    .clk(clk),
    .ready(fs_go),
    .valid(fs_valid),
    .empty(fs_done),
    .data({core_interrupt, peripheral_interrupt, isr_return,
           peripheral_isr_number, r0_in, r1_in, r2_in, r3_in, pc_in})
  );
  
  FileCompare #(
    .DATA_WIDTH(FC_DATA_WIDTH),
    .FILE_PATH(FILE_COMPARE)
  ) compare (
    .clk(clk),
    .valid(isr_restore),
    .data({r0_out, r1_out, r2_out, r3_out, pc_out}),
    .done(done),
    .error(error)
  );
  
  W0RM_Core_Interrupt #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .ISR_WIDTH(ISR_WIDTH)
  ) dut (
    .clk(clk),
    
    .core_interrupt(fs_valid && core_interrupt),
    .peripheral_interrupt(fs_valid && peripheral_interrupt),
    
    .isr_addr_valid(isr_addr_valid),
    .isr_addr(isr_addr),
    
    .isr_return(fs_valid && isr_return),
    
    .r0_in(r0_in),
    .r1_in(r1_in),
    .r2_in(r2_in),
    .r3_in(r3_in),
    .pc_in(pc_in),
    
    .isr_restore(isr_restore),
    .r0_out(r0_out),
    .r1_out(r1_out),
    .r2_out(r2_out),
    .r3_out(r3_out),
    .pc_out(pc_out)
  );
endmodule
