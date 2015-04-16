`timescale 1ns/100ps

/*
    |->  valid  ->|
    |<-  ready  <-| 
    |->  data   ->|
*/

module W0RM_Synchro #(
  parameter DATA_WIDTH  = 32,
  parameter SYNC_READY  = 0
)(
  input wire                    clk,
  input wire                    reset,
  input wire                    input_valid,
  output wire                   input_ready,
  input wire  [DATA_WIDTH-1:0]  input_data,
  
  input wire                    output_ready,
  output wire                   output_valid,
  output wire [DATA_WIDTH-1:0]  output_data
);
  reg                     valid_r = 0;
  reg                     ready_r = 0;
  reg   [DATA_WIDTH-1:0]  data_r = 0;
  
  generate
    if (SYNC_READY)
    begin
      assign input_ready  = ready_r;
    end
    else
    begin
      assign input_ready  = output_ready;
    end
  endgenerate
  
  assign output_valid = valid_r;
  assign output_data  = data_r;
  
  always @(posedge clk)
  begin
    if (reset)
    begin
      valid_r <= 1'b0;
      ready_r <= 1'b0;
      data_r  <= {DATA_WIDTH{1'b0}};
    end
    else
    begin
      if (output_ready)
      begin
        ready_r <= 1'b1;
        if (input_valid)
        begin
          valid_r <= 1'b1;
          data_r  <= input_data;
        end
        else
        begin
          valid_r <= 1'b0;
          data_r  <= {DATA_WIDTH{1'b0}};
        end
      end
      else
      begin
        ready_r <= 1'b0;
      end
    end
  end
endmodule
