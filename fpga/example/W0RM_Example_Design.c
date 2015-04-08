; Walnut Zero RISC Machine example design program
; This program uses a delay loop to toggle an LED

struct gpio_t
{
  uint32_t  enable,
            control,
            input_data,
            output_data;
};

struct counter_t
{
  uint32_t  control,
            timer,
            load,
            reset;
};

void main(void)
{
  struct gpio_t* gpio_a = (struct gpio_t*)(0x80000080);
  int   delay;
  
  gpio_a->control = 0xff;
  gpio_a->enable  = 0xff;
  
  while (1)
  {
    gpio_a->output_data ^= 1;
    
    delay = 0x00ff0000;
    
    while (--delay != 0);
  }
}
