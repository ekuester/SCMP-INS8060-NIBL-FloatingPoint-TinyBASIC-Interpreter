#!/usr/bin/env python3
# simple SC/MP disassembler
# python version of Phil Green's c version
# writes labels into json file (added by ek)
# set tabbed to False [default: True] to to get a normal listing with addressses and opcodes
# set xppc3_call to False [default: True] to get normal behavior of XPPC P3

import json, re, sys

def usage():
    print("SC/MP disassembler by Phil Green")
    print("<http://www.mccrash-racing.co.uk/philg/>")
    print("converts binary file to SC/MP mnemonics")
    print("rewritten for python > 3.9 March 18, 2023")
    print("enhanced for floating point NIBL by Erich Küster")
    print("Usage:   disass4scmp infile [ hex_start_address ] [ > outfile ]")
    print("Example: disass4scmp binfile DFC1 > mylist.dsm")
    quit()

# output for feeding into macro assembler, set to False to get normal listing
tabbed = True
# set xppc_call to True to recognize call macro
xppc3_call = True
# set memory begin for valid xppc call
xppc3_begin = 0xCF
argc = len(sys.argv)
if (argc != 2 and argc != 3):
    usage()
base = sys.argv[1]
file_bin = base + ".bin"
# start address
start = 0
# program counter
pc = 0
if (argc == 3):
    start = sys.argv[2]
    pc = int(start,16)
# put labels in a list
labels = []
lines = []

with open(file_bin, "rb") as bin_f:
    bin_bytes = bytes(bin_f.read())
i = 0
bytes_range = range(len(bin_bytes))
while i in bytes_range:
    # line holds four fields: 0 address, 1 opcode, 2 label, 3 mnemonic, 4 remainder, 5 target
    line = []
    # save program counter
    addr = pc
    opcode = bin_bytes[i]
    # increment byte counter
    i += 1
    # increment program counter after reading one byte
    pc += 1
    # the two lower bits define which pointer if needed later
    ptr = opcode & 3
    # save address field
    line.append(f"{addr:04X} : ")
    # default is illegal code
    mnemonic = "illegal opcode?"
    remainder = ""
    target = ""
    if (opcode == 0x3f) and xppc3_call:
        if i in bytes_range:
            # look for potential xppc3 call or return
            first = bin_bytes[i]
            if first == 0:
                # return from subroutine
                i += 1
                pc += 1
                line.append(f"{opcode:02X}00 ")
                line.append("        ")
                line.append(f"RTRN P{ptr}")
                lines.append(line)
                continue
            if first > xppc3_begin:
                # call subroutine only beyond given address
                line.append(f"{opcode:02X}   ")
                line.append("        ")
                lines.append(line)
                line = []
                addr = pc
                line.append(f"{addr:04X} : ")
                i += 1
                pc += 1
                second = bin_bytes[i]
                i += 1
                pc += 1
                dest = first * 256 + second
                line.append(f"{dest:04X} ")
                line.append("        ")
                line.append("CALL    ")
                # remainder
                line.append(f"P3,${dest:04X}")
                labels.append(f"{dest:04X}")
                lines.append(line) 
                continue
    if opcode < 0x80:
        # one byte instructions
        line.append(f"{opcode:02X}   ")
        match opcode:
            # Extension Register Instructions
            case 0x40:  mnemonic = "LDE"
            case 0x01:  mnemonic = "XAE"
            case 0x50:  mnemonic = "ANE"
            case 0x58:  mnemonic = "ORE"
            case 0x60:  mnemonic = "XRE"
            case 0x68:  mnemonic = "DAE"
            case 0x70:  mnemonic = "ADE"
            case 0x78:  mnemonic = "CAE"
            # Pointer Register Move Instructions
            case 0x30 | 0x31 | 0x32 | 0x33:
                mnemonic = "XPAL    "
                remainder = f"P{ptr}"
            case 0x34 | 0x35 | 0x36 | 0x37:
                mnemonic = "XPAH    "
                remainder = f"P{ptr}"
            case 0x3c | 0x3d | 0x3e | 0x3f:
                mnemonic = "XPPC    "
                remainder = f"P{ptr}"
            # Shift, Rotate, Serial I/O Instructions
            case 0x19:  mnemonic = "SIO"
            case 0x1c:  mnemonic = "SR"
            case 0x1d:  mnemonic = "SRL"
            case 0x1e:  mnemonic = "RR"
            case 0x1f:  mnemonic = "RRL"
            # Single Byte Miscellaneous Instructions
            case 0x00:  mnemonic = "HALT"
            case 0x02:  mnemonic = "CCL"
            case 0x03:  mnemonic = "SCL"
            case 0x04:  mnemonic = "DINT"
            case 0x05:  mnemonic = "IEN"
            case 0x06:  mnemonic = "CSA"
            case 0x07:  mnemonic = "CAS"
            case 0x08:  mnemonic = "NOP"
    else:
        # two byte instructions
        pc += 1
        arg = bin_bytes[i]
        i += 1
        line.append(f"{opcode:02X}{arg:02X} ")
        ats = ""
        dest = ""
        if arg == 0x80:
            # take extension reg as displacement
            # to do: is incorrect for pc related instructions, e.g. JMP
            ats = ats + "EREG"
            dest = dest + "EREG"
        else:
            # to do: configure auto indexed mode better $FE71 ?????
            page = pc & 0xf000
            if arg & 0x80:
                disp = 0xff00 + arg
                algn = arg - 256
                ats = f"{algn:03}"
                n_pc = pc + disp
            else:
                ats = f"+{arg:02}"
                argn = arg
                n_pc = pc + arg
            n_pc = page + (n_pc & 0x0fff)
            dest = f"{n_pc:04X}"

        atsptr = f"{ats}(P{ptr})"
        # match since python 3.10 possible
        match opcode:
            # Memory Reference Instructions
            case 0xc0 :
                mnemonic = "LD      "
                remainder = f"{ats}    "
                target = f" ; at ${dest}"
            case 0xc1 | 0xc2 | 0xc3 :
                mnemonic = "LD      "
                remainder = f"{atsptr}"
            case 0xc5 | 0xc6 | 0xc7 :
                mnemonic = "LD      "
                remainder = f"@{atsptr}    "
            case 0xc8 :
                mnemonic = "ST      "
                remainder = f"{ats}    "
                target = f" ; to ${dest}"
            case 0xc9 | 0xca | 0xcb :
                mnemonic = "ST      "
                remainder = f"{atsptr}    "
            case 0xcd | 0xce | 0xcf :
                mnemonic = "ST      "
                remainder = f"@{atsptr}    "
            case 0xd0 :
                mnemonic = "AND     "
                remainder = f"{ats}    "
                target = f" ; at ${dest}"
            case 0xd1 | 0xd2 | 0xd3 :
                mnemonic = "AND     "
                remainder = f"{atsptr}    "
            case 0xd5 | 0xd6 | 0xd7 :
                mnemonic = "AND     "
                remainder = f"@{atsptr}    "
            case 0xd8 :
                mnemonic = "OR      "
                remainder = f"{ats}    "
                target = f" ; at ${dest}"
            case 0xd9 | 0xda | 0xdb :
                mnemonic = "OR      "
                remainder = f"{atsptr}    "
            case 0xdd | 0xde | 0xdf :
                mnemonic = "OR      "
                remainder = f"@{atsptr}    "
            case 0xe0 :
                mnemonic = f"XOR      "
                remainder = f"{ats}    "
                target = f" ; at ${dest}"
            case 0xe1 | 0xe2 | 0xe3 :
                mnemonic = f"XOR    {atsptr}"
            case 0xe5 | 0xe6 | 0xe7 :
                mnemonic = "XOR     "
                remainder = f"@{atsptr}"
            case 0xe8 :
                mnemonic = "DAD     "
                remainder = f"{ats}    "
            case 0xe9 | 0xea | 0xeb :
                mnemonic = "DAD     "
                remainder = f"{atsptr}"
            case 0xed | 0xee | 0xef :
                mnemonic = "DAD     "
                remainder = f"@{atsptr}"
            case 0xf0 :
                mnemonic = "ADD     "
                remainder = f"{ats}    "
                target = f" ; at ${dest}"
            case 0xf1 | 0xf2 | 0xf3 :
                mnemonic = "ADD     "
                remainder = f"{atsptr}"
            case 0xf5 | 0xf6 | 0xf7 :
                mnemonic = "ADD     "
                remainder = f"@{atsptr}"
            case 0xf8 :
                mnemonic = "CAD     "
                remainder = f"{ats}    "
                target = f" ; at ${dest}"
            case 0xf9 | 0xfa | 0xfb :
                mnemonic = "CAD     "
                remainder = f"{atsptr}    "
            case 0xfd | 0xfe | 0xff :
                mnemonic = "CAD     "
                remainder = f"@{atsptr}"

            # Memory Increment/Decrement Instructions
            case 0xa8 | 0xa9 | 0xaa | 0xab :
                mnemonic = "ILD     "
                remainder = f"{atsptr}"
            case 0xb8 | 0xb9 | 0xba | 0xbb :
                mnemonic = "DLD     "
                remainder = f"{atsptr}"
            # Immediate Instructions
            case 0xc4 :
                mnemonic = f"LDI     "
                remainder = f"0x{arg:02X}"
            case 0xd4 :
                mnemonic = "ANI     "
                remainder = f"0x{arg:02X}"
            case 0xdc :
                mnemonic = "ORI     "
                remainder = f"0x{arg:02X}"
            case 0xe4 :
                mnemonic = "XRI     "
                remainder = f"0x{arg:02X}"
            case 0xec :
                mnemonic = "DAI     "
                remainder = f"0x{arg:02X}"
            case 0xf4 :
                mnemonic = "ADI     "
                remainder = f"0x{arg:02X}"
            case 0xfc :
                mnemonic = "CAI     "
                remainder = f"0x{arg:02X}"

            # Jump Instructions
            # store only direct jump destination as label
            case 0x90 :
                mnemonic = "JMP     "
                remainder = f"${ats}   "
                target = f" ; to ${dest}"
                labels.append(dest)
            case 0x91 | 0x92 | 0x93 :
                mnemonic = "JMP     "
                remainder = f"{atsptr}"
            case 0x94 :
                mnemonic = "JP      "
                remainder = f"${ats}   "
                target = f" ; to ${dest}"
                labels.append(dest)
            case 0x95 | 0x96 | 0x97 :
                mnemonic = "JP      "
                remainder = f"{atsptr}"
            case 0x98 :
                mnemonic = "JZ      "
                remainder = f"${ats}   "
                target = f" ; to ${dest}"
                labels.append(dest)
            case 0x99 | 0x9a | 0x9b :
                mnemonic = "JZ      "
                remainder = f"{atsptr}"
            case 0x9c :
                mnemonic = "JNZ     "
                remainder = f"${ats}   "
                target = f" ; to ${dest}"
                labels.append(dest)
            case 0x9d | 0x9e | 0x9f :
                mnemonic = "JNZ     "
                remainder = f"{atsptr}  "
            # double-byte miscellaneous instruction
            case 0x8f:
                mnemonic = "DLY     "
                remainder = f"0x{arg:02X}"
            # default case
            case _:
                mnemonic ="illegal opcode?"
        #append mnemonic, remainder,target ??
    # pass 1: add place for label
    line.append("        ")
    if mnemonic:
        line.append(mnemonic)
    if remainder:
        line.append(remainder)
    if target:
        line.append(target)
    lines.append(line)

# delete duplicates and sort labels
real_labels = list(set(labels))
real_labels.sort()

# second pass: add labels and replace by names if possible
with open("symbol_table.json", "r") as name_f:
    names = json.load(name_f)

for line in lines:
    label = line[0][0:4]
    if label in names.keys():
        colon = names[label] + ':'
        line[2] = f"{colon:8}"
    else:
        if label in real_labels:
            line[2] = f"${label}:  "
# third pass: replace $ labels by name (if found) and print lines (if normal listing desired)
for line in lines:
    llen = len(line)
    if llen > 4:
        label = line[llen-1][-4:]
        if label in names.keys():
            # kill $ label
            line[llen-1] = line[llen-1][0:-5] + names[label]
    if not tabbed:
        for field in line:
            print(field, end='')
        print()

if tabbed:
    # prepare code for inserting into macro assembly
    for line in lines:
        # strip address and opcode field
        del line[0:2]
        label = line[0]
        if not label.isspace() and re.match(r'\$', label):
            # rename only label beginning with $
            line[0] = f"L_{label[1:7]}"
        if len(line) == 4:
            # insert jump target
            line[2] = line[3][6:]
            del line[3]
        for field in line:
           print(field, end='')
        print()

# write labels to file for further editing
label_file = base + ".json"
with open(label_file, "w") as json_f:
    json_f.write(json.dumps(real_labels))

print("νενικήκαμεν")

