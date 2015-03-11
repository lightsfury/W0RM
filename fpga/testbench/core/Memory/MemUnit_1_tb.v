`timescale 1ns/100ps

module MemUnit_1_tb(
  output wire done,
              error
);
  MemUnit_base_tb #(
    .FILE_SOURCE("../testbench/data/core/Memory/MemUnit_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/Memory/MemUnit_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
