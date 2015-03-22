; Walnut Zero RISC Machine example design program
; This program uses a delay loop to toggle an LED

; Setup the memory address
; Set R4 to value 0x80000080
MOV R4, #0x80
LSL R4, #24
MOV R5, #0x80
ADD R4, R5

toggle_led:

; Read-modify-write the GPIO data register
; The GPIO data register is located at offset 0x04
LDR R0, [R4, #4]
XOR R0, #1
STR R0, [R4, #4]

; Set R1 to value 0x00FF0000
MOV R1, #0xFF
LSL R1, 16

loop_head:

; decrement R1
SUB R1, #1
; if R1 is now 0, toggle the led and repeat
BZS toggle_led
; otherwise, continue decrementing R1
B   loop_head
