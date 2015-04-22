`timescale 1ns/100ps

module W0RM_Core_IFetch #(
  parameter SINGLE_CYCLE  = 0,
  parameter ENABLE_CACHE  = 0,
  parameter ADDR_WIDTH    = 32,
  parameter DATA_WIDTH    = 32,
  parameter INST_WIDTH    = 16,
  parameter START_PC      = 32'h2000_0000
)(
  input wire                    clk,
  input wire                    reset,
  
  input wire                    branch_data_valid,
                                branch_flush,
  input wire  [ADDR_WIDTH-1:0]  next_pc,
  input wire                    next_pc_valid,
  
  input wire                    decode_ready,
  output wire                   ifetch_ready,
  
  output wire [ADDR_WIDTH-1:0]  reg_pc,
  output wire                   reg_pc_valid,
  
  input wire  [INST_WIDTH-1:0]  inst_data_in,
  input wire                    inst_valid_in,
  input wire  [ADDR_WIDTH-1:0]  inst_addr_in,
  
  output wire [INST_WIDTH-1:0]  inst_data_out,
  output wire                   inst_valid_out,
  output wire [ADDR_WIDTH-1:0]  inst_addr_out
);

  generate
    if (ENABLE_CACHE == 0)
    begin
      reg   [ADDR_WIDTH-1:0]  reg_pc_r = START_PC, inst_addr_r = 0;
      reg   [INST_WIDTH-1:0]  inst_data_r = 0;
      reg                     flush_next_inst_r = 0,
                              flush_next_inst_r2 = 0,
                              flush_next_inst_r3 = 0;
      reg                     inst_valid_r = 0;
      reg   [ADDR_WIDTH-1:0]  last_inst_addr_r = START_PC;
      
      assign flush_i          = flush_next_inst_r || flush_next_inst_r2 || flush_next_inst_r3;
      assign reg_pc           = reg_pc_r;
      assign inst_valid_out   = inst_valid_r && ~reset;
      assign inst_data_out    = inst_data_r;
      assign ifetch_ready     = decode_ready && ~reset;
      assign reg_pc_valid     = decode_ready && ~reset && ~flush_i;
      assign inst_addr_out    = inst_addr_r;
      
      always @(posedge clk)
      begin
        if (reset)
        begin
          reg_pc_r            <= START_PC;
          inst_addr_r         <= START_PC;
          last_inst_addr_r    <= START_PC;
          inst_data_r         <= {DATA_WIDTH{1'b0}};
          flush_next_inst_r   <= 1'b0;
          flush_next_inst_r2  <= 1'b0;
          flush_next_inst_r3  <= 1'b0;
        end
        else if (branch_data_valid && next_pc_valid)
        begin
          reg_pc_r          <= next_pc;
          inst_addr_r       <= next_pc;
          flush_next_inst_r <= 1'b1;
          inst_valid_r      <= 1'b0;
        end
        else if (decode_ready)
        begin
          inst_valid_r        <= inst_valid_in && ~flush_i;
          flush_next_inst_r   <= 1'b0;
          flush_next_inst_r2  <= flush_next_inst_r;
          flush_next_inst_r3  <= flush_next_inst_r2;
          last_inst_addr_r    <= (inst_valid_in && ~flush_i) ? inst_addr_in : inst_addr_r;
          
          if (/* inst_valid_in && */~flush_i)
          begin
            reg_pc_r            <= reg_pc_r + 2;
            inst_addr_r         <= inst_addr_in;
            inst_data_r         <= inst_data_in;
          end
          else
          begin
            reg_pc_r          <= reg_pc_r;
            inst_addr_r       <= inst_addr_in;
            inst_data_r       <= inst_data_in;
          end
        end
        else
        begin
          reg_pc_r            <= last_inst_addr_r + 2;
        end
      end
    end
    else
    begin
      //! @todo Create cache and control structures
    end
  endgenerate

endmodule