; Walnut Zero RISC Machine example program boot loader
; This program reads the values on GPIO C and loads the specified program

main:

NOP

; Initialize GPIO C
; Setup address 0x80000080
MOV   R4, #0x80
LSL   R4, #20
ADD   R4, #0x08
LSL   R4, #4

; Setup GPIO C as input
MOV   R2, #0
STORE R2, [R4, #4]
MOV   R2, #0xFF
STORE R2, [R4, #0]

MOV   R0, #0x80

; Wait ~64 clock cycles (~1.3us) for the inputs to stabilize
wait_loop:
SUB   R0, #1
BZC   wait_loop

LOAD  R0, [R4, #8]

; Disable GPIO C
MOV   R2, #0
STORE R2, [R4, #0]

AND   R0, #0x03

; SUB   R0, #0
BZS   call_prog_0
SUB   R0, #1
BZS   call_prog_1
SUB   R0, #1
BZS   call_prog_2
SUB   R0, #1
BZS   call_prog_3

; Jump back to main
B     main

call_prog_0:
; Branch to 0x2100_0000
MOV   R1, #0x21
LSL   R1, #24
BX    R1

call_prog_1:
; Branch to 0x2200_0000
MOV   R1, #0x22
LSL   R1, #24
BX    R1

call_prog_2:
; Branch to 0x2300_0000
MOV   R1, #0x23
LSL   R1, #24
BX    R1

call_prog_3:
; Branch to 0x2400_0000
MOV   R1, #0x24
LSL   R1, #24
BX    R1

NOP
NOP
NOP
NOP