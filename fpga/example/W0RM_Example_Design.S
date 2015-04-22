; Walnut Zero RISC Machine example design program
; This program uses a delay loop to toggle an LED

NOP

; Setup the memory address
; Set R4 to value 0x80000080
MOV R4, #0x80
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
LSL R4, #24
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
MOV R5, #0x80
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
ADD R4, R5
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP

; Initialize the GPIO pins
MOV R2, #0
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
SUB R2, #1
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; Setup the GPIO as outputs
STORE R2, [R4, #4]
; NOP
; NOP
; NOP
; NOP
; Enable the GPIO pins
STORE R2, [R4, #0]
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP

toggle_led:

; Read-modify-write the GPIO data register
; The GPIO data register is located at offset 0x04
LOAD R0, [R4, #12]
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
XOR R0, #1
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
STORE R0, [R4, #12]
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP

; Set R1 to value 0x00FF0000
MOV R1, #0x4
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
LSL R1, #16
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP

loop_head:

; decrement R1
SUB R1, #1
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; if R1 is now 0, toggle the led and repeat
BZC   loop_head
; BZS toggle_led
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; otherwise, continue decrementing R1
B     toggle_led
; B   loop_head
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP
; NOP

ADD R15,#0
; NOP