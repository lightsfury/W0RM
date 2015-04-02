`timescale 1ns/100ps

module W0RM_Peripheral_GPIO #(
  parameter ADDR_WIDTH  = 32,
  parameter DATA_WIDTH  = 32,
  parameter BASE_ADDR   = 32'h80000080,
  parameter GPIO_WIDTH  = 8
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
  
  inout wire  [GPIO_WIDTH-1:0]  pin_gpio_pad
);
  localparam  ADDR_STRIDE = 16;
  localparam  PIN_INPUT   = 1'b0;
  localparam  PIN_OUTPUT  = 1'b1;
  
  localparam  DECODE_EN   = 0;
  localparam  DECODE_CTRL = 4;
  localparam  DECODE_IDR  = 8;
  localparam  DECODE_ODR  = 12;
  
  reg   [DATA_WIDTH-1:0]  idr   = 0,
                          odr   = 0,
                          ctrl  = 0,
                          en    = 0;
  reg   [GPIO_WIDTH-1:0]  pin_gpio_pad_r = 0;
  reg                     mem_valid_o_r = 0;
  reg   [DATA_WIDTH-1:0]  mem_data_o_r = 0;
  wire                    mem_decode_ce;
  
  assign mem_decode_ce  = (mem_addr_i >= BASE_ADDR) && (mem_addr_i <= (BASE_ADDR + ADDR_STRIDE));
  assign mem_valid_o    = mem_valid_o_r;
  assign mem_data_o     = mem_data_o_r;
  
  always @(posedge mem_clk)
  begin
    if (cpu_reset)
    begin
      en            <= 0;
      ctrl          <= 0;
      odr           <= 0;
      mem_valid_o_r <= 1'b0;
    end
    else if (mem_valid_i && mem_decode_ce)
    begin
      mem_data_o_r  <= {DATA_WIDTH{1'b0}};
      if (mem_read_i)
      begin
        case(mem_addr_i[3:0])
          DECODE_EN:
            mem_data_o_r  <= en;
          
          DECODE_CTRL:
            mem_data_o_r  <= ctrl;
          
          DECODE_IDR:
            mem_data_o_r  <= idr;
          
          DECODE_ODR:
            mem_data_o_r  <= odr;
          
          default:
            mem_data_o_r  <= {DATA_WIDTH{1'b0}};
        endcase
      end
      
      if (mem_write_i)
      begin
        case(mem_addr_i[3:0])
          DECODE_EN:
            en    <= mem_data_i;
          
          DECODE_CTRL:
            ctrl  <= mem_data_i;
          
          //DECODE_IDR:
            // IDR register is read-only
          
          DECODE_ODR:
            odr   <= mem_data_i;
          
          default:
          begin
            // By default, do nothing
          end
        endcase
      end
    end
    
    mem_valid_o_r <= mem_valid_i && mem_decode_ce;
  end
  
  genvar i;
  generate
    for (i = 0; i < GPIO_WIDTH; i = i + 1)
    begin: gpio_pad_begin
      always @(posedge mem_clk)
      begin
        if (cpu_reset)
        begin
          pin_gpio_pad_r[i] <= 1'b0;
          idr[i]            <= 1'b0;
        end
        else if (en[i])
        begin
          if (ctrl[i] == PIN_OUTPUT)
          begin
            pin_gpio_pad_r[i] <= odr[i];
          end
          else if (ctrl[i] == PIN_INPUT)
          begin
            idr[i] <= pin_gpio_pad[i];
          end
        end
      end
      
      assign pin_gpio_pad[i] = (en[i] && ctrl[i] == PIN_OUTPUT) ? pin_gpio_pad_r[i] : 1'bz;
    end
  endgenerate
endmodule
