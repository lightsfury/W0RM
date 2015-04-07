`timescale 1ns/100ps

module W0RM_Peripheral_Counter #(
  parameter ADDR_WIDTH  = 32,
  parameter DATA_WIDTH  = 32,
  parameter BASE_ADDR   = 32'h81000000,
  parameter TIME_WIDTH  = 32
)(
  input wire                    mem_clk,
                                cpu_reset,
  
  input wire                    mem_valid_i,
                                mem_read_i,
                                mem_write_i,
  input wire  [ADDR_WIDTH-1:0]  mem_addr_i,
  input wire  [DATA_WIDTH-1:0]  mem_data_i,
  
  output wire                   mem_valid_o,
  output wire [DATA_WIDTH-1:0]  mem_data_o,
  
  output wire                   timer_reload
);
  localparam  ADDR_STRIDE = 16;
  localparam  COUNT_UP    = 1;
  localparam  COUNT_DOWN  = 0;
  localparam  DECODE_HIGH = 4;
  localparam  DECODE_LOW  = 0;
  
  localparam  DECODE_CTRL   = 0;
  localparam  DECODE_TIME   = 4;
  localparam  DECODE_LOAD   = 8;
  localparam  DECODE_RESET  = 12;
  
  localparam  CTRL_BIT_EN   = 0;
  localparam  CTRL_BIT_DIR  = 1;
  
  reg   [DATA_WIDTH-1:0]  ctrl = 0,
                          timer = 0,
                          load = 0,
                          reset = 0;
  reg   [DATA_WIDTH-1:0]  mem_data_o_r = 0;
  reg                     mem_valid_o_r = 0;
  
  wire                    mem_decode_ce;
  wire  [DECODE_HIGH-1:0] mem_decode_addr_i;
  reg                     timer_reload_r = 0;
  
  assign mem_decode_ce = (mem_addr_i >= BASE_ADDR) && (mem_addr_i < (BASE_ADDR + ADDR_STRIDE));
  assign mem_decode_addr_i = mem_addr_i[DECODE_HIGH:DECODE_LOW];
  
  assign mem_data_o   = mem_data_o_r;
  assign mem_valid_o  = mem_valid_o_r;
  assign timer_reload = timer_reload_r;
  
  always @(posedge mem_clk)
  begin
    if (cpu_reset)
    begin
      ctrl          <= {DATA_WIDTH{1'b0}};
      timer         <= {DATA_WIDTH{1'b0}};
      load          <= {DATA_WIDTH{1'b0}};
      reset         <= {DATA_WIDTH{1'b0}};
      mem_valid_o_r <= 1'b0;
      mem_data_o_r  <= {DATA_WIDTH{1'b0}};
      timer_reload_r  <= 1'b0;
    end
    else if (mem_valid_i && mem_decode_ce)
    begin
      mem_data_o_r  <= {DATA_WIDTH{1'b0}};
      
      if (mem_read_i)
      begin
        case (mem_decode_addr_i)
          DECODE_CTRL:
            mem_data_o_r  <= ctrl;
          
          DECODE_TIME:
            mem_data_o_r  <= timer;
          
          DECODE_LOAD:
            mem_data_o_r  <= load;
          
          DECODE_RESET:
            mem_data_o_r  <= reset;
          
          default:
            mem_data_o_r  <= {DATA_WIDTH{1'b0}};
        endcase
      end
      
      if (mem_write_i)
      begin
        case (mem_decode_addr_i)
          DECODE_CTRL:
            ctrl  <= mem_data_i;
          
          DECODE_TIME:
            timer <= mem_data_i;
          
          DECODE_LOAD:
            load  <= mem_data_i;
          
          DECODE_RESET:
            reset <= mem_data_i;
          
          default:
          begin
            // No-op
          end
        endcase
      end
    end
    
    timer_reload_r  <= 1'b0;
    
    if (ctrl[CTRL_BIT_EN])
    begin
      if (~(mem_valid_i && mem_write_i && mem_decode_ce && (mem_decode_addr_i == DECODE_TIME)))
      begin
        // Writing to a register other than DECODE_TIME
        if (ctrl[CTRL_BIT_DIR] == COUNT_UP)
        begin
          timer <= timer + 1;
        end
        else
        begin
          timer <= timer - 1;
        end
        
        if (timer == reset)
        begin
          timer         <= load;
          timer_reload_r  <= 1'b1;
          
          //! @todo Add a rollover signal/interrupt
        end
      end
    end
    
    mem_valid_o_r <= mem_valid_i && mem_decode_ce;
  end

endmodule
