; Walnut Zero RISC Machine example program boot loader
; This program reads the values on GPIO C and loads the specified program

main:

NOP                         ; 00

; Initialize GPIO C
; Setup address 0x80000080
MOV   R4, #0x80             ; 02
LSL   R4, #20               ; 04
ADD   R4, #0x08             ; 06
LSL   R4, #4                ; 08

; Setup GPIO C as input
MOV   R2, #0                ; 0a
STORE R2, [R4, #4]          ; 0c
MOV   R2, #0xFF             ; 0e
STORE R2, [R4, #0]          ; 10

MOV   R0, #0x80             ; 12

; Wait ~64 clock cycles (~1.3us) for the inputs to stabilize
wait_loop:
SUB   R0, #1                ; 14
BZC   wait_loop             ; 16

LOAD  R0, [R4, #8]          ; 18

; Disable GPIO C
MOV   R2, #0                ; 1a
STORE R2, [R4, #0]          ; 1c

AND   R0, #0x03             ; 1e

; SUB   R0, #0
BZS   call_prog_0           ; 20
SUB   R0, #1                ; 22
BZS   call_prog_1           ; 24
SUB   R0, #1                ; 26
BZS   call_prog_2           ; 28
SUB   R0, #1                ; 2a
BZS   call_prog_3           ; 2c

; Jump back to main
B     main                  ; 2e

call_prog_0:
; Branch to 0x2100_0000
MOV   R1, #0x21             ; 30
LSL   R1, #24               ; 32
BX    R1                    ; 34

call_prog_1:
; Branch to 0x2200_0000
MOV   R1, #0x22             ; 36
LSL   R1, #24               ; 38
BX    R1                    ; 3a

call_prog_2:
; Branch to 0x2300_0000
MOV   R1, #0x23             ; 3c
LSL   R1, #24               ; 3e
BX    R1                    ; 40

call_prog_3:
; Branch to 0x2400_0000
MOV   R1, #0x24             ; 42
LSL   R1, #24               ; 44
BX    R1                    ; 46

NOP                         ; 48
NOP                         ; 4a
NOP                         ; 4c
NOP                         ; 4e
