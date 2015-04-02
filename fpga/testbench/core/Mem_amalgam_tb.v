`timescale 1ns/100ps

module Mem_amalgam_tb(
  output wire done,
              error
);
  Memory_bus_1_tb(
    .done(done_mem_1),
    .error(error_mem_1)
  );

  Memory_bus_2_tb(
    .done(done_mem_2),
    .error(error_mem_2)
  );

  Memory_inst_1_tb(
    .done(done_mem_3),
    .error(error_mem_3)
  );

  Memory_inst_2_tb(
    .done(done_mem_4),
    .error(error_mem_4)
  );
  
  assign done   = done_mem_1 && done_mem_2 && done_mem_3 && done_mem_4;
  assign error  = error_mem_1 || error_mem_2 || error_mem_3 || error_mem_4;
endmodule
