`timescale 1ns/100ps

module W0RM_Sync_1_tb(
  output wire done,
              error
);
  W0RM_Sync_base_tb #(
    .DATA_WIDTH(8),
    .FILE_SOURCE("../testbench/data/W0RM_Sync_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/W0RM_Sync_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
