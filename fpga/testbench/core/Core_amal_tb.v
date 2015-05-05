`timescale 1ns/100ps

module Core_amal_tb(
  output wire done,
              error
);
  /*
  Mem_amalgam_tb mem_amal_tb(
    .done(mem_done),
    .error(mem_error)
  ); // */
  
  ALU_amalgam_tb alu_amal_tb(
    .done(alu_done),
    .error(alu_error)
  );
  
  /*
  Decode_amalgam_tb decode_amal_tb(
    .done(decode_done),
    .error(decode_error)
  ); // */
  
  IFetch_1_tb ifetch_1_tb(
    .done(ifetch_1_done),
    .error(ifetch_1_error)
  );
  
  RegisterFile_wbr1_tb regfile_wbr1_tb(
    .done(reg_1_done),
    .error(reg_1_error)
  );
  
  RegisterFile_2p1_tb regfile_2port1_tb(
    .done(reg_2_done),
    .error(reg_2_error)
  );
  
  RegisterFile_tb1 regfile_1_tb(
    .done(reg_3_done),
    .error(reg_3_error)
  );
  
  Branch_1_tb branch_1_tb(
    .done(branch_done),
    .error(branch_error)
  );
  
  W0RM_TopLevel_1_tb w0rm_toplevel_1_tb(
    .done(top_level_done),
    .error(top_level_error)
  );
  
  //MemUnit_1_tb();
  
  assign done = alu_done /* && decode_done */ && ifetch_1_done && reg_1_done && reg_2_done && reg_3_done && branch_done && top_level_done;
  assign error = alu_error /* || decode_error */ || ifetch_1_error || reg_1_error || reg_2_error || reg_3_error || branch_error || top_level_error;
endmodule
