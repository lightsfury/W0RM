`timescale 1ns/100ps

module LCD_1_tb(
  output wire done,
              error
);
  LCD_base_tb #(
    .FILE_SOURCE("../testbench/data/peripheral/lcd/LCD_1_tb_data.txt"),
    .FILE_COMPARE("../testbench/data/peripheral/lcd/LCD_1_tb_compare.txt")
  ) dut (
    .done(done),
    .error(error)
  );
endmodule
