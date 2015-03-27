#! /bin/python3

import sys
import re

alu_operand_to_opcode = {
  'AND': 0,
  'OR': 1,
  'XOR': 2,
  'NOT': 3,
  'NEG': 4,
  'MUL': 5,
  'DIV': 6,
  'REM': 7,
  'ADD': 8,
  'SUB': 9
}

shift_operand_to_opcode = {
  'LSR': 0,
  'LSL': 1,
  'ASR': 2
}

def encode_nop(s):
  return 0

def encode_extend(s):
  base = 0x1000;
  
  if s.operand[0] == 'Z':
    base += 0x0800
  
  if s.operand[4] == 'H':
    base += 0x0400
  
  reg = int(s.params[1:])
  
  return base + (reg * 16)

def encode_cond_branch(s):
  # Figure out how to calculate branch distance
  pass

def encode_mov(s):
  opcode = alu_operand_to_opcode[s.operand]
  
  params = s.params.split(',')
  
  rd = int(params[0][1:])
  rn = int(params[1][1:])
  
  base = 0x4000
  
  if params[1][0] == '#':
    base += 0x1000
  
  return base + (rd * 4096)  + rn

def encode_load_store(s):
  base = 0x6000
  
  if s.operand == 'STORE':
    base += 0x1000
  
  params = s.params.split(',')
  
  rd = int(params[0][1:])
  rn = int(params[1][1:])
  lit = int(params[2][1:-1])
  
  return base + (rd * 4096) + (rn * 256) + lit

def encode_alu(s):
  opcode = alu_operand_to_opcode[s.operand]
  
  params = s.params.split(',')
  
  rd = int(params[0][1:])
  rn = int(params[1][1:])
  
  base = 0x8000
  
  if params[1][0] == 'R':
    base += 0x1000
  
  return base + (opcode * 256) + (rd * 16) + rn
  
  pass

def encode_shift(s):
  opcode = shift_operand_to_opcode[s.operand]
  
  params = s.params.split(',')
  
  rd = int(params[0][1:])
  rn = int(params[1][1:])
  
  base = 0xA000
  
  if params[1][0] == 'R':
    base += 0x1000
  
  return base + (rd * 256) + (opcode * 64) + rn

def encode_push_pop(s):
  base = 0xE000
  
  if s.operand == 'POP':
    base += 0x0100
  
  rd = int(s.params[1:])
  
  return base + rd

def encode_branch(s):
  # Figure out how to calculate branch distance
  pass

operands = {
  'NOP': encode_nop,
  'SEXTB': encode_extend,
  'SEXTH': encode_extend,
  'ZEXTB': encode_extend,
  'ZEXTH': encode_extend,
  'BZS': encode_cond_branch,
  'BZC': encode_cond_branch,
  'BCS': encode_cond_branch,
  'BCC': encode_cond_branch,
  'BNS': encode_cond_branch,
  'BNC': encode_cond_branch,
  'BVS': encode_cond_branch,
  'BVC': encode_cond_branch,
  'BLZS': encode_cond_branch,
  'BLZC': encode_cond_branch,
  'BLCS': encode_cond_branch,
  'BLCC': encode_cond_branch,
  'BLNS': encode_cond_branch,
  'BLNC': encode_cond_branch,
  'BLVS': encode_cond_branch,
  'BLVC': encode_cond_branch,
  'MOV': encode_mov,
  'LOAD': encode_load_store,
  'STORE': encode_load_store,
  'AND': encode_alu,
  'OR': encode_alu,
  'XOR': encode_alu,
  'NOT': encode_alu,
  'NEG': encode_alu,
  'MUL': encode_alu,
  'DIV': encode_alu,
  'REM': encode_alu,
  'ADD': encode_alu,
  'SUB': encode_alu,
  'LSR': encode_shift,
  'LSL': encode_shift,
  'ASR': encode_shift,
  'PUSH': encode_push_pop,
  'POP': encode_push_pop,
  'B': encode_branch,
  'BL': encode_branch,
  'BX': encode_branch,
  'BLX': encode_branch
}

def strip_comments(lines):
  c = re.compile(r'^\s*([^;]*)\s*;.*$')
  new_lines = [c.sub(r'\1', line) for line in lines]
  return new_lines

def strip_empty_lines(lines):
  c = re.compile(r'^\s*$')
  new_lines = [line for line in lines if not c.match(line)]
  return new_lines

def normalize_params(lines):
  c = re.compile(r', ');
  new_lines = [c.sub(',', line) for line in lines]
  return new_lines

def strip_extra_spaces(lines):
  c = re.compile(r'^\s*([A-Za-z]+\s?[A-Za-z,#0-9_\[\]]*)\s*$')
  new_lines = [c.sub(r'\1', line) for line in lines]
  return new_lines

def extract_mnemonic(lines):
  c = re.compile(r'^([A-Za-z]{1,5})\s?([A-Za-z,#0-9_\[\]]*)$')
  m = [c.match(line) for line in lines]
  p = [{'operand': k.group(1).upper, 'params': k.group(2)} for k in m if k]
  return p

