`timescale 1ns/100ps

module Counter_1_tb(
  output wire done,
              error
);
  Counter_base_tb #(
    .FILE_SOURCE("../testbench/data/peripheral/counter/Counter_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/peripheral/counter/Counter_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
