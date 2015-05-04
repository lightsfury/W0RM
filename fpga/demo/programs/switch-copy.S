; Walnut Zero RISC Machine example program 2
; This program copies the GPIO switch inputs to the
; GPIO led outputs
NOP
; Setup GPIO led address 0x80000000
MOV   R4, #0x80
LSL   R4, #24
; ADD   R4, #4
; LSL   R4, #4

; Setup GPIO switch address 0x80000040
MOV   R5, #0x80
LSL   R5, #20
ADD   R5, #4
LSL   R5, #4

; Initial GPIO switch pins
MOV   R2, #0
; Set control register to 0x00 (PIN_INPUT)
STORE R2, [R5, #4]
MOV   R2, #0xFF
;SUB   R2, #1
; Set enable register to 0xFF (enabled)
STORE R2, [R5, #0]

; Initial GPIO switch pins
MOV   R2, #0
SUB   R2, #1
; Set control register to 0xFF (PIN_OUTPUT)
STORE R2, [R4, #4]
; Set enable register to 0xFF (enabled)
STORE R2, [R4, #0]

main_loop:
; Get GPIO switch values
LOAD  R0, [R5, #8]
STORE R0, [R4, #12]

; Loop 0x80000 times (983,040)
MOV   R0, #0x1F
LSL   R0, #4
ADD   R0, #4

wait_loop:
SUB   R0, #1
BZC   wait_loop

B     main_loop

; Dummy instructions to match 32-bit alignment
NOP
NOP
NOP
NOP
NOP
NOP
NOP