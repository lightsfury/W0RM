`timescale 1ns/100ps

module RegisterFile_wbr1_tb(
  output wire done,
              error
);
  RegisterFile_write_before_read_tb #(
    .DATA_WIDTH(8),
    .NUM_REGISTERS(4),
    .FILE_SOURCE("../testbench/data/core/RegisterFile_tb1_write_data.txt"),
    .FILE_COMPARE("../testbench/data/core/RegisterFile_tb1_data_compare.txt")
  ) dut (
    .done(done),
    .error(error));
endmodule
