`timescale 1ns/100ps

module Memory_inst_1_tb;
  Memory_inst_base_tb #(
    .BLOCK_RAM(1),
    .BASE_ADDR(0),
    .FILE_SOURCE("../testbench/data/core/Memory/Memory_inst_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/Memory/Memory_inst_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
