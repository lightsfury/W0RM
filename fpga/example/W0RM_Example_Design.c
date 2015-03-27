; Walnut Zero RISC Machine example design program
; This program uses a delay loop to toggle an LED

struct gpio_t
{
  int enable,
      input_data,
      output_data;
};

void main(void)
{
  struct gpio_t* gpio_a = (struct gpio_t*)(0x80000080);
  int   delay;
  
  while (1)
  {
    gpio_a->output_data ^= 1;
    
    delay = 0x00ff0000;
    
    while (--delay != 0);
  }
}