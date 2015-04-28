; Walnut Zero RISC Machine example program 1
; This program uses a delay loop to toggle an LED
NOP
; Setup the memory address
; Set R4 to value 0x80000040
MOV R4, #0x80
LSL R4, #24
MOV R5, #0x40
ADD R4, R5
; Initialize the GPIO pins
MOV R2, #0xFF
; SUB R2, #1
; Setup the GPIO as outputs
STORE R2, [R4, #4]
; Enable the GPIO pins
STORE R2, [R4, #0]
toggle_led:
; Read-modify-write the GPIO data register
; The GPIO data register is located at offset 0x04
LOAD R0, [R4, #12]
XOR R0, #1
STORE R0, [R4, #12]
; Set R1 to value 0x00FF0000
MOV R1, #0x4
LSL R1, #16
loop_head:
; decrement R1
SUB R1, #1
; if R1 is now 0, toggle the led and repeat
BZC   loop_head
; BZS toggle_led
; otherwise, continue decrementing R1
B     toggle_led
; Dummy instructions to match 32-bit alignment
NOP
NOP
NOP
NOP
NOP
NOP
NOP