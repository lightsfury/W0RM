`timescale 1ns/100ps

module Periph_amal_tb(
  output wire done,
              error
);
  Counter_1_tb(
    .done(ctr_1_done),
    .error(ctr_1_error)
  );
  
  GPIO_1_tb(
    .done(gpio_1_done),
    .error(gpio_1_error)
  );
  
  W0RM_Sync_1_tb(
    .done(sync_1_done),
    .error(sync_1_error)
  );
  
  W0RM_Sync_ALU_1_tb(
    .done(sync_2_done),
    .error(sync_2_error)
  );
  
  assign done = ctr_1_done && gpio_1_done && sync_1_done && sync_2_done;
  assign error = ctr_1_error || gpio_1_error || sync_1_error || sync_2_error;

endmodule
