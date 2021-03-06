#! /usr/bin/python3 

import sys
import re
from functools import reduce

def asm_output_coe(file, lines, start_address=0, output_width=32, mem_depth=-1):
  file.write('memory_initialization_radix=16;\nmemory_initialization_vector=\n')
  
  for i in range(0, len(lines), int(output_width / 16)):
    for j in range (0, int(output_width / 16)):
      if (i + j) < len(lines):
        file.write('%0.4x' % lines[i + j])
      else:
        file.write('0000')
    if (i + (output_width / 16)) >= len(lines):
      file.write(';')
    else:
      file.write(",\n")

def asm_output_hex(file, lines, start_address=0, output_width=32, mem_depth=-1):
  #file.write('@ 0x%0x\n' % start_address)
  for i in range(0, len(lines), int(output_width / 16)):
    for j in range (0, int(output_width / 16)):
      if (i + j) < len(lines):
        file.write('%0.4x' % lines[i + j])
      else:
        file.write('%0.4x' % 0)
    file.write("\n")
  if mem_depth > 0:
    for i in range(len(lines), mem_depth, int(output_width / 16)):
      for j in range (0, int(output_width / 16)):
        file.write('%0.4x' % 0)
      file.write("\n")

def asm_output_bin(file, lines, start_address=0, output_width=32, mem_depth=-1):
  #file.write('@ 0x%0x\n' % start_address)
  for i in range(0, len(lines), int(output_width / 16)):
    for j in range (0, int(output_width / 16)):
      if (i + j) < len(lines):  
        file.write('{0:0<016b}'.format(lines[i + j]))
      else:
        file.write('{0:0<016b}'.format(0))
    file.write("\n")
  #print(mem_depth)
  if mem_depth > 0:
    for i in range(len(lines), mem_depth, int(output_width / 16)):
      for j in range (0, int(output_width / 16)):
        file.write('{0:0<016b}'.format(0))
      file.write("\n")

asm_output_fuctions = {
  'coe': asm_output_coe,
  'hex': asm_output_hex,
  'bin': asm_output_bin
}

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

cond_branch_operand_to_opcode = {
  'ZS': 0,
  'ZC': 1,
  'CS': 2,
  'CC': 3,
  'VS': 4,
  'VC': 5,
  'NS': 6,
  'NC': 7
}

def resolve_label(label, cur_addr, labels):
  def map_labels(x):
    return x['label']
  
  def map_for_reduce(x):
    return x if x['label']==label else None
  
  def reduce_labels(accum, next_entry):
    return accum if accum is not None else next_entry
  
  if label in map(map_labels, labels):
    m = map(map_for_reduce, labels)
    r = reduce(reduce_labels, m)
    
    dist = r['addr'] - (cur_addr + 2)
    
    #print("resolve_label (%s) r['addr']=%x, cur_addr=%x dist=%d\n" % (label, int(r['addr']), cur_addr, dist))
    
    return dist
  else:
    #print("resolve_label: label %s not found" % label)
    raise Exception("resolve_label: label %s not found" % label)
    return -1

def encode_nop(s, cur_addr, labels):
  return 0

def encode_extend(s, cur_addr, labels):
  base = 0x1000;
  
  if s['operand'][0] == 'Z':
    base += 0x0800
  
  if s['operand'][4] == 'H':
    base += 0x0400
  
  reg = int(s['params'][1:], 0)
  
  return base + (reg * 16)

def encode_cond_branch(s, cur_addr, labels):
  base = 0x2000
  
  lit = 0
  
  if 'X' in s['operand']:
    # Branch to register address
    param = int(s['params'][1:], 0)
    
    base += 0x1000
  else:
    # Branch via relative jump
    label = s['params']
    
    param = resolve_label(label, cur_addr, labels)
  
  if 'L' in s['operand']:
    base += 0x0800
  
  cond_opcode = cond_branch_operand_to_opcode[s['operand'][-2:]]
  
  if param > 0xff:
    raise BaseException("Conditional branch distance too large (%d) for branch instruction at address 0x%0.8x" % (param, cur_addr))
  
  return base + (cond_opcode * 0x0100) + (param % 0x0100)

def encode_mov(s, cur_addr, labels):
  params = s['params'].split(',')
  
  rd = int(params[0][1:], 0)
  rn = int(params[1][1:], 0)
  
  base = 0x4000
  
  if params[1][0] == '#':
    base += 0x1000
  
  return base + (rd * 0x0100) + rn

def encode_load_store(s, cur_addr, labels):
  base = 0x6000
  
  if s['operand'] == 'STORE':
    base += 0x1000
  
  params = s['params'].split(',')
  
  rd = int(params[0][1:], 0)
  rn = int(params[1][2:], 0)
  lit = int(params[2][1:-1], 0)
  
  #print("load/store: rd=%d rn=%d lit=%d" % (rd, rn, lit))
  
  return base + (rd * 0x0100) + (rn * 0x0010) + lit

def encode_alu(s, cur_addr, labels):
  opcode = alu_operand_to_opcode[s['operand']]
  
  params = s['params'].split(',')
  
  rd = int(params[0][1:], 0)
  rn = int(params[1][1:], 0)
  
  base = 0x8000
  
  if params[1][0] == 'R':
    base += 0x1000
  
  return base + (opcode * 256) + (rd * 16) + rn

def encode_shift(s, cur_addr, labels):
  opcode = shift_operand_to_opcode[s['operand']]
  
  params = s['params'].split(',')
  
  rd = int(params[0][1:], 0)
  rn = int(params[1][1:], 0)
  
  base = 0xA000
  
  if params[1][0] == 'R':
    base += 0x1000
  
  return base + (rd * 0x0100) + (opcode * 0x0040) + rn

def encode_push_pop(s, cur_addr, labels):
  base = 0xE000
  
  if s['operand'] == 'POP':
    base += 0x0100
  
  rd = int(s['params'][1:], 0)
  
  return base + rd

def encode_branch(s, cur_addr, labels):
  base = 0xF000
  
  lit = 0
  
  if 'X' in s['operand']:
    # Branch to register address
    param = int(s['params'][1:], 0)
    
    base += 0x0800
  else:
    # Branch via relative jump
    label = s['params']
    
    param = resolve_label(label, cur_addr, labels)
  
  if 'L' in s['operand']:
    base += 0x0400
  
  if param > 0x3ff:
    raise BaseException("Unconditional branch distance too large (%d) for branch instruction at address 0x%0.8x" % (param, cur_addr))
  else:
    return base + (param % 0x0400)

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
  c = re.compile(r'^\s*([A-Za-z]+\s*?[A-Za-z,#0-9_\[\]]*)[\s\r\n]*$')
  new_lines = [c.sub(r'\1', line) for line in lines]
  return new_lines

def extract_mnemonic(lines):
  c = re.compile(r'^([A-Za-z]{1,5})\s*?([A-Za-z,#0-9_\[\]]*)$')
  m = [c.match(line) for line in lines]
  p = [{'operand': k.group(1).upper(), 'params': k.group(2)} for k in m if k]
  return p

def extract_labels(lines, start_address = 0):
  c = re.compile(r'^([A-Za-z0-9_]+):$')
  labels = []
  new_lines = []
  i = start_address
  
  for line in lines:
    g = c.match(line)
    if g:
      labels.append({'addr':i, 'label':g.group(1)})
    else:
      new_lines.append(line)
      i += 2
  
  return (labels, new_lines)

def encode_assembly(lines, labels, start_address = 0):
  i = start_address
  values = []
  
  for line in lines:
    op = line['operand']
    f = operands[op]
    v = f(line, i, labels)
    #v = operands[line['operand']](line, i, labels)
    i += 2
    values.append(v)
    
  #encoded_values = ['%0.4x' % v for v in values]
  
  return values

def run_assembler(input_file, output_file, output_type = 'coe', output_width = 32, start_address=0x20000000, mem_depth=-1):
  with open(input_file) as f:
    lines = f.readlines()
  
  lines = strip_comments(lines)
  lines = strip_empty_lines(lines)
  lines = normalize_params(lines)
  lines = strip_extra_spaces(lines)
  (labels, lines) = extract_labels(lines)
  #print(labels)
  #print(lines)
  lines = extract_mnemonic(lines)
  #print(lines)
  lines = encode_assembly(lines, labels, start_address=start_address)
  #print(lines)
  
  with open(output_file, 'w') as f:
    asm_output_fuctions[output_type](f, lines, start_address=start_address, output_width=output_width, mem_depth=mem_depth)

if __name__=="__main__":
  import sys
  import argparse
  
  def str_lower(*pargs, **kargs):
    s = str(*pargs, **kargs)
    return s.lower()
  
  parser = argparse.ArgumentParser(description = 'Generate byte code for the Walnut Zero Architecture', formatter_class=argparse.RawDescriptionHelpFormatter)
  group = parser.add_argument_group('Output type', 'specify output file type')
  group.add_argument('--output-type', '-t', metavar='<output-type>', type=str_lower, help = "specify output type\n  coe: Format for Xilinx Block Memory Generator IP Core\n  hex: hexadecimal output for use with $readmemh\n  bin: binary output for use with $readmemb", default='coe', choices=['coe', 'hex', 'bin'])
  # Optional start address
  parser.add_argument('--start-address', '-s', metavar='<start address>', type=lambda x: int(x, 0), help='base address to load memory at', default=0x2000000)
  # Optional data width
  parser.add_argument('--data-width', '-w', metavar='<data width>', type=lambda x: int(x, 0), help='Number of bits to encode at each address', default=32)
  # Optional memory depth
  parser.add_argument('--mem-depth', '-d', metavar='<memory depth>', type=lambda x: int(x, 0), help='Depth of the memory in words of <data width> bits in size', default=-1)
  # Positional arguments
  parser.add_argument('input_file', metavar='<input file>', type=str, help='input file path')
  parser.add_argument('output_file', metavar='<output file>', type=str, help='output file path')
  args = parser.parse_args()
  
  #print(args)
  #print(args.input_type
  #print(sys.argv)
  run_assembler(args.input_file, args.output_file, output_type=args.output_type, start_address=args.start_address, output_width=args.data_width, mem_depth=args.mem_depth)
  