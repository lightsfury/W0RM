`timescale 1ns/100ps

module Periph_visual_tb(
  output wire done,
              error
);
  LCD_1_tb lcd_1_tb(
    .done(lcd_1_done),
    .error(ld_1_error)
  );

endmodule