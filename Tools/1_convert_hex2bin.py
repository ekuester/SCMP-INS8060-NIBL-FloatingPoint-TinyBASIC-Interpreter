#!/usr/bin/env python3
# structure of hexadecimal line: address ; 32 chars 0..9, A..F
# D000;C40C3FD500C41CDC0135C40031C400C9
# first line gives start address

import binascii
import sys

def usage():
    print("converts hexadecimal dump into binary file")
    print("first line gives start address")
    print("usage: ./1_convert_hex2bin.py hexfile")
    print("give hexfile without .hex extension")
    print("Erich Küster April 2023")
    quit()

argc = len(sys.argv)
if argc == 1:
    usage()
base = sys.argv[1]
hexfile = base + ".hex"

print(f"hexfile: {hexfile}")
# first read hex file into a list and split at ; after address
lines = []
with open(hexfile) as hex_f:
    first_line = hex_f.readline()
    lines.append(first_line[5:-1])
    # read rest of file
    for line in hex_f:
        pos = line.find(';') + 1
        if pos > 0:
            lines.append(line[pos:-1])
    base = first_line[0:4]
    binfile = base + ".bin"
    print(f"binfile: {binfile}")
    with open(binfile, "wb") as bin_f:
        for line in lines:
            chunk = binascii.unhexlify(line)
            bin_f.write(chunk)
print("Done!")

