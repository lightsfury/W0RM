`timescale 1ns/100ps

module ALU_Logic_1_tb(
  output wire done,
              error
);
  ALU_Logic_base_tb #(
    .DATA_WIDTH(8),
    .FILE_SOURCE("../testbench/data/core/ALU_Logic_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/ALU_Logic_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error));
endmodule
