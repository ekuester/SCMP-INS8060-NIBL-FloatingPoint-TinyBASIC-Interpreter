#!/usr/bin/env python3
# FPBASIC Ver 7.9
# show table of interpretative language at D802
#
# terminated by double zero bytes
# usage: view_il_table.py basefilename startaddress

import binascii
import json
import sys

def usage():
    print("SC/MP Floating Point Basic by Erich Küster")
    print("show table of interpretative language")
    print("written for python > 3.9 March 23, 2023")
    print("Usage: view_il_table.py basefilename startaddress [ > outfile ]")
    print("Example: view_il_table.py file DB00 > mylist.dsm")

# set tabbed to True to get feed for macro assembly
tabbed = True
argc = len(sys.argv)
base = sys.argv[1]
start = sys.argv[2]
address = int(start,16)
file_bin = base + ".bin"
print(f"binfile: {file_bin}")
token_tab = ['AUTO', 'BYE', 'CLEAR', 'CLOAD', 'CSAVE', 'EDIT', 'LIST', 'NEW',\
             'RUN', 'DATA', 'DEF', 'DIM', 'DO', 'ELSE', 'END', 'FOR', 'GOSUB',\
             'GOTO', 'IF', 'INPUT', 'LINK', 'MAT', 'NEXT', 'ON', 'PAGE', 'POKE',\
             'PRINT', 'PR', 'READ', 'REM', 'RESTORE', 'RETURN', 'STAT', 'UNTIL',\
             'LET', 'AND', 'DIV', 'EXOR', 'MOD', 'OR', 'PEEK', '<=', '>=', '<>',\
             'ABS', 'ATN', 'COS', 'EXP', 'FN', 'INT', 'LB', 'LG', 'LN', 'NOT',\
             'PI', 'RND', 'SGN', 'SIN', 'SQR', 'TAN', 'VAL', 'ASC', 'FREE',\
             'LEN', 'POS', 'TOP', 'STEP', 'THEN', 'TO', 'CHR$', 'LEFT$', 'MID$',\
             'RIGHT$', 'SPC', 'STR$', 'TAB', 'USING', 'VERT']
pc = 0
if (argc == 3):
   pc = int(sys.argv[2],16)
# put labels in a list
labels = []
lines = []

try:
    with open(file_bin, "rb") as bin_f:
        while (byte := bin_f.read(1)):
            # create new line
            line = []
            # save program counter
            addr = pc
            pc += 1
            opcode = byte[0]
            # line holds four fields: 0 label, 1 address, 2 command, 3 mnemonic, 4 target
            # pass 1: place for label
            line.append("        ")
            line.append(f"{addr:04X}")
            if opcode == 0:
                line.append(f"  {opcode:02X}    ")
                line.append("END")
                lines.append(line)
            else:
                # read second byte
                byte = bin_f.read(1)
                low = byte[0]
                pc += 1
                menmonic = ""
                # the four highest bits define the I.L. commands
                code = opcode & 0xF0
                if code == 0x90:
                    # special 3 byte case
                    command = opcode * 256  + byte[0]
                    line.append(f"  {command:04X}")
                    addr = pc
                    # complete address
                    command += 0x4000
                    line.append("  TSTSTR  ")
                    line.append(f"${command:04X}")
                    lines.append(line)
                    # read byte for testing
                    byte = bin_f.read(1)
                    pc += 1
                    # add new line
                    line = []
                    line.append("        ")
                    line.append(f"{addr:04X}")
                    token = byte[0]
                    line.append(f"  {token:02X}    ")
                    if token < 0x80:
                        if token < 0x20:
                            # control characters
                            line.append(f"  DB      0x{token:02X}")
                        else:
                            line.append(f"  DB      '{chr(token)}'")
                    else:
                        index = token & 0x7f
                        token_str = token_tab[index]
                        count = 7 - len(token_str)
                        padding = " " * count
                        mnemonic = f"  DB      0x{token:02X}          ;'{token_str}'{padding}"
                        line.append(mnemonic)
                    lines.append(line)
                else:
                    if code == 0xE0 or code == 0xF0:
                        command = opcode * 256 + byte[0]
                        mnemonic = "  DO      "
                    elif code == 0xD0:
                        command = opcode * 256 + byte[0]
                        mnemonic = "  TSTNUM  "
                    elif code == 0xB0:
                        command = (opcode + 32) * 256 + byte[0]
                        mnemonic = "  TSTVAR  "
                    elif code == 0x50:
                        command = (opcode + 128) * 256  + byte[0]
                        mnemonic = "  GOTO    "
                    elif code == 0x10:
                        command = (opcode + 192) * 256 + byte[0]
                        mnemonic = "  ILCALL  "
                    else:
                        mnemonic = "  UNKNOWN"
                    line.append(f"  {opcode:02X}{low:02X}")
                    line.append(mnemonic)
                    line.append(f"${command:04X}")
                    lines.append(line)
                label = f"{command:04X}"
                if label not in labels:
                    labels.append(label)
    bin_f.close()

except FileNotFoundError:
    msg = "Sorry, some file may not exist."
    print(msg)

# sort labels
labels.sort()
# second pass: add labels and print lines, substitute by names if possible
with open("names_merged.json", "r") as name_f:
    names = json.load(name_f)
    for line in lines:
        label = line[1]
        if label in labels:
            if label in names.keys():
                colon = names[label] + ':'
                line[0] = f"{colon:8}"
            else:
                line[0] = f"${label}:  "
        if len(line) > 4:
            label = line[4][-4:]
            if label in names.keys():
                # kill $ label
                line[4] = line[4][0:-5] + names[label]
        if not tabbed:
            for field in line:
                print(field, end='')
            print()
if tabbed:
    # prepare code for inserting into macro assembly
    for line in lines:
        # strip address and opcode field
        del line[1:3]
        # strip 2 spaces at begin
        line[1] = line[1][2:]
        for field in line:
           print(field, end='')
        print()

# write labels to file for further editing
label_file = base + ".json"
with open(label_file, "w") as json_f:
    json_f.write(json.dumps(labels))
print("νενικήκαμεν")

