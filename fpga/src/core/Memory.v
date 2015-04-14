`timescale 1ns/100ps

module W0RM_Core_Memory #(
  parameter SINGLE_CYCLE  = 0,
  parameter USER_WIDTH    = 1,
  parameter ADDR_WIDTH    = 32,
  parameter DATA_WIDTH    = 32
)(
  input wire                    clk,
  
  output wire                   mem_ready,
                                mem_output_valid,
  output wire [DATA_WIDTH-1:0]  mem_data_out,
  
  input wire                    mem_write,
                                mem_read,
                                mem_is_pop,
  input wire  [ADDR_WIDTH-1:0]  mem_data,
                                mem_addr,
  input wire                    mem_valid_i,

  output wire                   data_bus_write_out,
                                data_bus_read_out,
                                data_bus_valid_out,
  output wire [ADDR_WIDTH-1:0]  data_bus_addr_out,
  output wire [DATA_WIDTH-1:0]  data_bus_data_out,
  
  input wire  [DATA_WIDTH-1:0]  data_bus_data_in,
  input wire                    data_bus_valid_in,
  
  input wire  [USER_WIDTH-1:0]  user_data_in,
  output wire [USER_WIDTH-1:0]  user_data_out
);
  reg   [USER_WIDTH-1:0]  user_data_r         = 0;
  reg                     pending_op          = 0,
                          mem_output_valid_r  = 0,
                          mem_write_r         = 0,
                          mem_read_r          = 0,
                          mem_is_pop_r        = 0;
  reg   [DATA_WIDTH-1:0]  mem_data_r          = 0;
  reg   [ADDR_WIDTH-1:0]  mem_addr_r          = 0;
  reg                     mem_valid_r         = 0;
  reg   [DATA_WIDTH-1:0]  mem_result_r        = 0;
  reg                     mem_ready_r         = 0;

  always @(posedge clk)
  begin
    mem_output_valid_r <= 1'b0;
    if (!pending_op)
    begin
      if (mem_valid_i)
      begin
        if (mem_write || mem_read) // Is this an event we care about?
        begin
          pending_op    <= 1'b1;
          mem_write_r   <= mem_write;
          mem_read_r    <= mem_read;
          mem_is_pop_r  <= mem_is_pop;
          mem_data_r    <= mem_data;
          mem_addr_r    <= mem_addr;
          mem_valid_r   <= 1'b1;
          user_data_r   <= user_data_in;
          mem_output_valid_r  <= 1'b0;
        end
        else
        begin
          // Not a real event, just pass it through
          user_data_r         <= user_data_in;
          mem_output_valid_r  <= 1'b1;
        end
      end
      else
      begin
        // Inputs not valid
        pending_op    <= 1'b0;
        mem_write_r   <= 0;
        mem_read_r    <= 0;
        mem_is_pop_r  <= 0;
        mem_addr_r    <= 0;
        mem_data_r    <= mem_data_r; // For forwarding
        mem_result_r  <= 0;
        mem_output_valid_r  <= 1'b0;
      end
    end
    else
    begin
      if (data_bus_valid_in)
      begin
        if (mem_read_r)
        begin
          mem_result_r  <= data_bus_data_in;
        end
        else
        begin
          mem_result_r  <= {DATA_WIDTH{1'b0}};
        end
        
        //! @todo Implement is_pop functionality
        
        mem_output_valid_r  <= 1'b1;
        pending_op          <= 1'b0;
      end
      
      mem_valid_r <= 1'b0;
    end
  end
  
  assign #0.1 data_bus_write_out  = mem_write_r;
  assign #0.1 data_bus_read_out   = mem_read_r;
  assign #0.1 data_bus_valid_out  = mem_valid_r;
  assign #0.1 data_bus_addr_out   = mem_addr_r;
  assign #0.1 data_bus_data_out   = mem_data_r;
  
  assign #0.1 mem_data_out        = mem_result_r;
  assign #0.1 mem_ready           = ~pending_op;
  assign #0.1 mem_output_valid    = mem_output_valid_r;
  
  assign #0.1 user_data_out       = user_data_r;
endmodule
