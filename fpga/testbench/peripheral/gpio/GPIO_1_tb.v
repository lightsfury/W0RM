`timescale 1ns/100ps

module GPIO_1_tb(
  output wire done,
              error
);
  GPIO_base_tb #(
    .FILE_SOURCE("../testbench/data/peripheral/gpio/GPIO_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/peripheral/gpio/GPIO_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );

endmodule
