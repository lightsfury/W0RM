`timescale 1ns/100ps

module IFetch_1_tb(
  output wire done,
              error
);
  IFetch_base_tb #(
    .FILE_SOURCE("../testbench/data/core/IFetch/IFetch_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/IFetch/IFetch_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
