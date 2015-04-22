`timescale 1ns/100ps

module W0RM_Core_Interrupt #(
  parameter DATA_WIDTH  = 32,
  parameter ADDR_WIDTH  = 32,
  parameter ISR_WIDTH   = 8
)(
  input wire                    clk,
  input wire                    core_interrupt,
  input wire                    peripheral_interrupt,
  input wire  [ISR_WIDTH-1:0]   peripheral_isr_number,
  
  output wire                   isr_addr_valid,
  output wire [ADDR_WIDTH-1:0]  isr_addr,
  
  input wire                    isr_return,
  
  input wire  [DATA_WIDTH-1:0]  r0_in,
                                r1_in,
                                r2_in,
                                r3_in,
                                pc_in,
  output wire                   isr_restore,
  output wire [DATA_WIDTH-1:0]  r0_out,
                                r1_out,
                                r2_out,
                                r3_out,
                                pc_out
  //! @todo Add a memory port for configuration
);
  function integer pow2(input integer n);
  integer i, j;
    begin
      i = 0;
      j = 1;
      while (i < n)
      begin
        i = i + 1;
        j = j * 2;
      end
      pow2 = j;
    end
  endfunction
  
  reg   [DATA_WIDTH-1:0]  r0_r = 0,
                          r1_r = 0,
                          r2_r = 0,
                          r3_r = 0,
                          pc_r = 0;
  reg   [ISR_WIDTH-1:0]   isr_vector_addr_r = 0;
  reg                     in_isr_r      = 0,
                          in_isr_r2     = 0,
                          isr_restore_r = 0;
  
  reg   [ADDR_WIDTH-1:0]  isr_vector  [pow2(ISR_WIDTH):0];
  
  task sample_interupt();
  begin
      r0_r  <= r0_in;
      r1_r  <= r1_in;
      r2_r  <= r2_in;
      r3_r  <= r3_in;
      pc_r  <= pc_in;
      in_isr_r  <= 1'b1;
      in_isr_r2 <= 1'b1;
      
      if (core_interrupt)
      begin
        isr_vector_addr_r <= 8'd0;
      end
      else if (peripheral_interrupt)
      begin
        isr_vector_addr_r <= peripheral_isr_number;
      end
    end
  endtask
  
  always @(posedge clk)
  begin
    isr_restore_r <= 1'b0;
    if (in_isr_r)
    begin
      in_isr_r2 <= 1'b0;
      
      if (isr_return)
      begin
        in_isr_r  <= 1'b0;
        
        if (core_interrupt || peripheral_interrupt)
        begin
          in_isr_r  <= 1'b1;
          in_isr_r2 <= 1'b1;
          
          if (core_interrupt)
          begin
            isr_vector_addr_r <= 8'd0;
          end
          else if (peripheral_interrupt)
          begin
            isr_vector_addr_r <= peripheral_isr_number;
          end
        end
        else
        begin
          isr_restore_r <= 1'b1;
        end
      end
    end
    else if (core_interrupt || peripheral_interrupt)
    begin
      r0_r  <= r0_in;
      r1_r  <= r1_in;
      r2_r  <= r2_in;
      r3_r  <= r3_in;
      pc_r  <= pc_in;
      in_isr_r  <= 1'b1;
      in_isr_r2 <= 1'b1;
      
      if (core_interrupt)
      begin
        isr_vector_addr_r <= 8'd0;
      end
      else if (peripheral_interrupt)
      begin
        isr_vector_addr_r <= peripheral_isr_number;
      end // */
      /*
      else
        How the fuck?
      */
    end
  end
  
  assign r0_out = r0_r;
  assign r1_out = r1_r;
  assign r2_out = r2_r;
  assign r3_out = r3_r;
  assign pc_out = pc_r;
  
  assign isr_addr_valid  = in_isr_r && in_isr_r2;
  assign isr_addr        = isr_vector[isr_vector_addr_r];
  assign isr_restore     = isr_restore_r;
endmodule
