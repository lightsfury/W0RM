`timescale 1ns/100ps

module W0RM_Peripheral_Bus_Extender #(
  parameter DATA_WIDTH  = 32,
  parameter ADD_REGS    = 0
)(
  input wire                    bus_clock,
  
  input wire                    bus_port0_valid_i,
  input wire  [DATA_WIDTH-1:0]  bus_port0_data_i,
  
  input wire                    bus_port1_valid_i,
  input wire  [DATA_WIDTH-1:0]  bus_port1_data_i,
  
  output wire                   bus_valid_o,
  output wire [DATA_WIDTH-1:0]  bus_data_o
);
  // Common operation
  reg   [DATA_WIDTH-1:0]  bus_data_o_r = 0;
  reg                     bus_valid_o_r = 0;
  
  always @(bus_port0_valid_i, bus_port1_valid_i, bus_port0_data_i, bus_port1_data_i)
  begin
    if (bus_port0_valid_i)
    begin
      bus_data_o_r  = bus_port0_data_i;
    end
    else if (bus_port1_valid_i)
    begin
      bus_data_o_r  = bus_port1_data_i;
    end
    else
    begin
      bus_data_o_r  = {DATA_WIDTH{1'b0}};
    end
  end
  
  generate
    if (ADD_REGS)
    begin
      // Add a register between the inputs and output
      reg                   bus_valid_o_r1 = 0;
      reg [DATA_WIDTH-1:0]  bus_data_o_r1 = 0;
      
      always @(posedge bus_clock)
      begin
        bus_valid_o_r1 <= bus_data_o_r;
        bus_data_o_r1  <= bus_data_o_r1;
      end
      
      assign bus_valid_o = bus_valid_o_r1;
      assign bus_data_o = bus_data_o_r1;
    end
    else
    begin
      // Pass through (mux) the data on the bus
      assign bus_valid_o = bus_valid_o_r;
      assign bus_data_o = bus_data_o_r;
    end
  endgenerate
  

endmodule
