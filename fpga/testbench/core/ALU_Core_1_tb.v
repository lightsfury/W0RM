`timescale 1ns/100ps

module ALU_Core_1_tb(
  output wire done,
              error
);
  ALU_Core_base_tb #(
    .DATA_WIDTH(32),
    .FILE_SOURCE("../testbench/data/core/ALU_Core_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/ALU_Core_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error));
endmodule
