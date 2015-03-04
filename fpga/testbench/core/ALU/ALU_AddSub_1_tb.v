`timescale 1ns/100ps

module ALU_AddSub_1_tb(
  output wire done,
              error
);
  ALU_AddSub_base_tb #(
    .DATA_WIDTH(32),
    .FILE_SOURCE("../testbench/data/core/ALU_AddSub_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/ALU_AddSub_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error));
endmodule
