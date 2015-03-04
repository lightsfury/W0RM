`timescale 1ns/100ps

module Decode_amalgam_tb(
  output wire done,
              error
);
  W0RM_Decode_1_tb decode_1(
    .done(decode_1_done),
    .error(decode_1_error)
  );
  
  W0RM_Decode_2_tb decode_2(
    .done(decode_2_done),
    .error(decode_2_error)
  );
  
  W0RM_Decode_3_tb decode_3(
    .done(decode_3_done),
    .error(decode_3_error)
  );
  
  W0RM_Decode_4_tb decode_4(
    .done(decode_4_done),
    .error(decode_4_error)
  );
  
  W0RM_Decode_5_tb decode_5(
    .done(decode_5_done),
    .error(decode_5_error)
  );
  
  W0RM_Decode_6_tb decode_6(
    .done(decode_6_done),
    .error(decode_6_error)
  );
  
  W0RM_Decode_7_tb decode_7(
    .done(decode_7_done),
    .error(decode_7_error)
  );
  
  W0RM_Decode_8_tb decode_8(
    .done(decode_8_done),
    .error(decode_8_error)
  );
  
  W0RM_Decode_9_tb decode_9(
    .done(decode_9_done),
    .error(decode_9_error)
  );
  
  W0RM_Decode_10_tb decode_10(
    .done(decode_10_done),
    .error(decode_10_error)
  );
  
  assign done = decode_1_done & decode_2_done & decode_3_done & decode_4_done & decode_5_done & decode_6_done & decode_7_done & decode_8_done & decode_9_done & decode_10_done;
  assign error = decode_1_error & decode_2_error & decode_3_error & decode_4_error & decode_5_error & decode_6_error & decode_7_error & decode_8_error & decode_9_error & decode_10_error;
endmodule
