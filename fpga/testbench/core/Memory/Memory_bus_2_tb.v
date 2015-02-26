`timescale 1ns/100ps

module Memory_bus_2_tb;
  Memory_bus_base_tb #(
    .BLOCK_RAM(0),
    .FILE_SOURCE("../testbench/data/core/Memory/Memory_bus_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/Memory/Memory_bus_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
