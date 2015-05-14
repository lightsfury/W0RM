`timescale 1ns/100ps

module W0RM_Peripheral_CharLCD_4bit #(
  parameter ADDR_WIDTH  = 32,
  parameter DATA_WIDTH  = 32,
  parameter BASE_ADDR   = 32'h4000_0000
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
  
  output wire                   lcd_bus_data_select,
                                lcd_bus_read_write,
                                lcd_bus_async_enable,
  inout wire  [3:0]             lcd_bus_data
);
  localparam  MEM_STRIDE    = 16;
  localparam  MEM_ADDR_LOW  = BASE_ADDR;
  localparam  MEM_ADDR_HIGH = BASE_ADDR + MEM_STRIDE;
  localparam  CTRL_EN       = 0;
  localparam  CTRL_RDY      = 1;
  localparam  CTRL_INIT     = 2;
  localparam  ADDR_CTRL     = 0;
  localparam  ADDR_INST     = 1;
  localparam  ADDR_DATA     = 2;
  localparam  DECODE_LOW    = 2;
  localparam  DECODE_HIGH   = 3;
  
  localparam  LCD_DRIVER_STATE_Idle         = 0;
  localparam  LCD_DRIVER_STATE_CmdSetup     = 1;
  localparam  LCD_DRIVER_STATE_EnMinHigh    = 2;
  localparam  LCD_DRIVER_STATE_EnMinCycle   = 3;
  localparam  LCD_DRIVER_STATE_EnMinHigh2   = 4;
  localparam  LCD_DRIVER_STATE_EnMinCycle2  = 5;
  localparam  LCD_DRIVER_STATE_CmdHold      = 6;
  
  reg   [2:0]     lcd_driver_state_r  = LCD_DRIVER_STATE_Idle;
  reg             lcd_driver_rs       = 0,
                  lcd_driver_rw       = 0,
                  lcd_driver_en       = 0,
                  lcd_cmd_setup_wait  = 0,
                  lcd_en_setup_wait   = 0;
  reg   [7:0]     lcd_driver_data_r   = 0;
  reg   [3:0]     lcd_driver_data_o   = 0;
  reg             lcd_bus_output_en   = 0;
  wire  [3:0]     lcd_bus_data_i,
                  lcd_bus_data_o;
  wire            lcd_cmd_setup_wait_done,
                  lcd_en_setup_wait_done,
                  lcd_en_min_cycle_done;
  
  wire                    mem_decode_ce = (mem_addr_i >= BASE_ADDR) && (mem_addr_i < MEM_ADDR_HIGH);
  
  reg   [DATA_WIDTH-1:0]  lcd_reg_inst = 0,
                          lcd_reg_data = 0;
  reg                     enable  = 0,
                          ready   = 0;
  
  reg                     mem_valid_o_r = 0;
  reg   [DATA_WIDTH-1:0]  mem_data_o_r = 0;
  
  assign lcd_bus_data_o       = lcd_driver_data_o;
  assign lcd_bus_async_enable = lcd_driver_en;
  assign lcd_bus_read_write   = lcd_driver_rw;
  assign lcd_bus_data_select  = lcd_driver_rs;
  assign mem_valid_o          = mem_valid_o_r;
  assign mem_data_o           = mem_data_o_r;
  
  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1)
    begin: generate_iobuf
      IOBUF lcd_bus_data_iobuf(
        .T(~lcd_bus_output_en),
        .I(lcd_bus_data_o[i]),
        .O(lcd_bus_data_i[i]),
        .IO(lcd_bus_data[i])
      );
    end
  endgenerate
  
  always @(posedge mem_clk)
  begin
    if (cpu_reset)
    begin
      enable  <= 0;
      ready   <= 0;
    end
    else
    begin
      // Memory action
      mem_valid_o_r <= mem_decode_ce && mem_valid_i && (mem_read_i || mem_write_i);
      if (mem_decode_ce && mem_valid_i)
      begin
        if (mem_write_i)
        begin
          mem_data_o_r  <= {DATA_WIDTH{1'b0}};
          case (mem_addr_i[DECODE_HIGH:DECODE_LOW])
            ADDR_CTRL:
              enable <= mem_data_i[0];
            
            ADDR_INST:
              lcd_reg_inst  <= mem_data_i;
            
            ADDR_DATA:
              lcd_reg_data  <= mem_data_i;
            
            default:
            begin
              // No-op
            end
          endcase
        end
        else if (mem_read_i)
        begin
          case (mem_addr_i[DECODE_HIGH:DECODE_LOW])
            ADDR_CTRL:
              mem_data_o_r  <= {{(DATA_WIDTH-2){1'b0}}, ready, enable};
            
            ADDR_INST:
              mem_data_o_r  <= lcd_reg_inst;
            
            ADDR_DATA:
              mem_data_o_r  <= lcd_reg_data;
            
            default:
              mem_data_o_r  <= {DATA_WIDTH{1'b0}};
          endcase
        end
      end
      
      // LCD bus action
      if (enable || (lcd_driver_state_r != LCD_DRIVER_STATE_Idle))
      begin
        case (lcd_driver_state_r)
          LCD_DRIVER_STATE_Idle:
          begin
            lcd_driver_data_r   <= 8'd0;
            lcd_driver_rs       <= 1'b0;
            lcd_driver_rw       <= 1'b0;
            lcd_driver_en       <= 1'b0;
            ready               <= 1'b1;
            lcd_cmd_setup_wait  <= 1'b0;
            if (mem_decode_ce && mem_valid_i && mem_write_i)
            begin
              if (mem_addr_i[DECODE_HIGH:DECODE_LOW] == ADDR_INST)
              begin
                lcd_driver_data_r   <= mem_data_i[7:0];
                lcd_driver_rs       <= 1'b1;
                lcd_driver_rw       <= 1'b0;
                lcd_driver_state_r  <= LCD_DRIVER_STATE_CmdSetup;
                ready               <= 1'b0;
                lcd_cmd_setup_wait  <= 1'b1;
              end
              else if (mem_addr_i[DECODE_HIGH:DECODE_LOW] == ADDR_DATA)
              begin
                lcd_driver_data_r   <= mem_data_i[7:0];
                lcd_driver_rs       <= 1'b0;
                lcd_driver_rw       <= 1'b0;
                lcd_driver_state_r  <= LCD_DRIVER_STATE_CmdSetup;
                ready               <= 1'b0;
                lcd_cmd_setup_wait  <= 1'b1;
              end
              /*
              else
                // Don't care
              */
            end
          end
          
          // Wait for RS to En setup time
          LCD_DRIVER_STATE_CmdSetup:
          begin
            lcd_cmd_setup_wait    <= 1'b0;
            lcd_en_setup_wait     <= 1'b0;
            
            if (lcd_cmd_setup_wait_done)
            begin
              lcd_driver_en       <= 1'b1;
              lcd_bus_output_en   <= 1'b1;
              lcd_en_setup_wait   <= 1'b1;
              lcd_driver_state_r  <= LCD_DRIVER_STATE_EnMinHigh;
              lcd_driver_data_o   <= lcd_driver_data_r[7:4];
            end
          end
          
          // Wait for En min high period
          LCD_DRIVER_STATE_EnMinHigh:
          begin
            lcd_en_setup_wait <= 1'b0;
            
            if (lcd_en_setup_wait_done)
            begin
              lcd_driver_en       <= 1'b0;
              lcd_driver_state_r  <= LCD_DRIVER_STATE_EnMinCycle;
            end
          end
          
          // Wait for En min cycle time
          LCD_DRIVER_STATE_EnMinCycle:
          begin
            lcd_driver_en <= 1'b0;
            if (lcd_en_min_cycle_done)
            begin
              lcd_driver_en       <= 1'b1;
              lcd_en_setup_wait   <= 1'b1;
              lcd_driver_state_r  <= LCD_DRIVER_STATE_EnMinHigh2;
              lcd_driver_data_o   <= lcd_driver_data_r[3:0];
            end
          end
          
          // Wait for En min high period
          LCD_DRIVER_STATE_EnMinHigh2:
          begin
            lcd_en_setup_wait <= 1'b0;
            
            if (lcd_en_setup_wait_done)
            begin
              lcd_driver_en       <= 1'b0;
              lcd_driver_state_r  <= LCD_DRIVER_STATE_EnMinCycle2;
            end
          end
          
          // Wait for En min cycle time
          LCD_DRIVER_STATE_EnMinCycle2:
          begin
            if (lcd_en_min_cycle_done)
            begin
              lcd_driver_state_r  <= LCD_DRIVER_STATE_CmdHold;
            end
          end
          
          LCD_DRIVER_STATE_CmdHold:
          begin
            lcd_bus_output_en <= 1'b0;
            lcd_en_setup_wait <= 1'b0;
            lcd_driver_en     <= 1'b0;
            lcd_driver_rs     <= 1'b0;
            lcd_driver_rw     <= 1'b0;
            lcd_driver_state_r  <= LCD_DRIVER_STATE_Idle;
          end
        endcase
      end
      else
      begin
        lcd_driver_state_r  <= LCD_DRIVER_STATE_Idle;
      end
    end
  end
  
  W0RM_Static_Timer #(
    .LOAD(0),
    .LIMIT(6)
  ) cmd_setup_timer (
    .clk(mem_clk),
    .start(lcd_cmd_setup_wait),
    .stop(lcd_cmd_setup_wait_done)
  );
  
  W0RM_Static_Timer #(
    .LOAD(0),
    .LIMIT(45)
  ) en_setup_timer (
    .clk(mem_clk),
    .start(lcd_en_setup_wait),
    .stop(lcd_en_setup_wait_done)
  );
  
  W0RM_Static_Timer #(
    .LOAD(0),
    .LIMIT(100)
  ) en_min_cycle_timer (
    .clk(mem_clk),
    .start(lcd_en_setup_wait),
    .stop(lcd_en_min_cycle_done)
  );
endmodule
