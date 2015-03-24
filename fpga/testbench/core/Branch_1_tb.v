`timescale 1ns/100ps

module Branch_1_tb(
  output wire done,
              error
);
  Branch_base_tb #(
    .DATA_WIDTH(32),
    .FILE_SOURCE("../testbench/data/core/Branch/Branch_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/Branch/Branch_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error));
endmodule
