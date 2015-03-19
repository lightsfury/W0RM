`timescale 1ns/100ps

module W0RM_Core_IFetch #(
  parameter SINGLE_CYCLE  = 0,
  parameter ENABLE_CACHE  = 0,
  parameter DATA_WIDTH    = 32,
  parameter INST_WIDTH    = 16,
  parameter START_PC      = 32'h2000_0000
)(
  input wire                    clk,
  input wire                    reset,
  
  input wire                    decode_ready,
  output wire                   ifetch_ready,
  
  output wire [DATA_WIDTH-1:0]  reg_pc,
  output wire                   reg_pc_valid,
  
  input wire  [INST_WIDTH-1:0]  inst_data_in,
  input wire                    inst_valid_in,
  
  output wire [INST_WIDTH-1:0]  inst_data_out,
  output wire                   inst_valid_out
);

  generate
    if (ENABLE_CACHE == 0)
    begin
      reg   [DATA_WIDTH-1:0]  reg_pc_r = START_PC;
      
      assign reg_pc = reg_pc_r;
      assign inst_valid_out = inst_valid_in && ~reset;
      assign inst_data_out = inst_data_in;
      assign ifetch_ready = decode_ready && ~reset;
      assign reg_pc_valid = decode_ready && ~reset;
      
      always @(posedge clk)
      begin
        if (reset)
        begin
          reg_pc_r <= START_PC;
        end
        else if (inst_valid_in)
        begin
          reg_pc_r <= reg_pc_r + 2;
        end
      end
    
    /*
      
      reg   [DATA_WIDTH-1:0]  reg_pc_r = START_PC;
      reg                     reg_pc_valid_r = 0;
      reg                     ifetch_ready_r = 0;
      reg   [INST_WIDTH-1:0]  instruction_r = 0;
      
      assign reg_pc = reg_pc_r;
      assign reg_pc_valid = reg_pc_valid_r;
      assign #0.1 ifetch_ready = decode_ready;
      
      assign inst_data_out = inst_data_in;
      
      //assign inst_data_out = inst_data_in;
      //assign inst_data_out = instruction_r;
      assign inst_valid_out = inst_valid_in;
      
      always @(posedge clk)
      begin
        // Reset action
        if (reset)
        begin
          reg_pc_r        <= START_PC;
          reg_pc_valid_r  <= 1'b0;
          ifetch_ready_r  <= 1'b0;
        end
        else if (decode_ready)
        begin
          reg_pc_r        <= reg_pc_r + 2;
          reg_pc_valid_r  <= 1'b1;
          ifetch_ready_r  <= 1'b1;
          instruction_r   <= inst_data_in;
        end
        else
        begin
          reg_pc_valid_r  <= 1'b0;
          ifetch_ready_r  <= 1'b1;
        end
      end // */
    end
    else
    begin
      //! @todo Create cache and control structures
    end
  endgenerate

endmodule