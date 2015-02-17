`timescale 1ns/100ps

module W0RM_Decode_5_tb;
  Decode_base_tb #(
    .FILE_SOURCE("../testbench/data/core/Decode_5_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/core/Decode_5_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
