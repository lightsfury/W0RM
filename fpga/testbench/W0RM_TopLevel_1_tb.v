`timescale 1ns/100ps

module W0RM_TopLevel_1_tb(
  output wire done,
              error
);
  W0RM_TopLevel_base_tb #(
    .FILE_SOURCE("../testbench/data/W0RM_TopLevel_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/W0RM_TopLevel_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
