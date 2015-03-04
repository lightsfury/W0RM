`timescale 1ns/100ps

module ALU_amalgam_tb(
  output wire done,
              error
);
  ALU_AddSub_1_tb add_sub_1(
    .done(add_sub_done),
    .error(add_sub_error)
  );

  ALU_DivRem_1_tb div_rem_1(
    .done(div_rem_done),
    .error(div_rem_error)
  );

  ALU_Logic_1_tb logic_1(
    .done(logic_done),
    .error(logic_error)
  );

  ALU_Mul_1_tb mul_1(
    .done(mul_done),
    .error(mul_error)
  );

  ALU_Shifts_1_tb shifts_1(
    .done(shifts_done),
    .error(shifts_error)
  );
  
  ALU_Core_1_tb core_1(
    .done(core_done),
    .error(core_error)
  );
  
  assign done   = add_sub_done & div_rem_done & logic_done & mul_done & shifts_done & core_done;
  assign error  = add_sub_error | div_rem_error | logic_error | mul_error | shifts_error | core_error;
endmodule
