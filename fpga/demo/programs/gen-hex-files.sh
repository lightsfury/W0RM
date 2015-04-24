#! /bin/sh

ASM='../../../assembler/w0rm-asm.py'

#echo ${ASM}
${ASM} -t hex -w 16 -s 0x20000000 boot-loader.S boot-loader.hex
${ASM} -t hex -w 16 -s 0x21000000 blink-led.S blink-led.hex
${ASM} -t hex -w 16 -s 0x22000000 switch-copy.S switch-copy.hex
