#!/usr/bin/env python3
# calculates new checksum for Intel HEX file
# 
# check_Intel_HEX.py

import binascii, sys

def usage():
    print("calculates new checksum for Intel HEX file")
    print("first line gives start address")
    print("usage: ./12_check_Intel_HEX.py [hexfile]")
    print("give hexfile without .hex extension")
    print("Erich Küster July 2023")
    quit()

argc = len(sys.argv)
if argc == 1:
    usage()
base = sys.argv[1]
hexfile = base + ".hex"

print(f"hexfile: {hexfile}")
# first read hex file into a list
line_bytes = []
with open(hexfile) as hex_f:
    # read file
    for line in hex_f:
        check = line[1:-3]
        hex_bytes = binascii.unhexlify(check)
        hex_bytes_sum = sum(hex_bytes)
        # one's complement
        hex_bytes_sum ^= 0xFF
        # add one for two's complement
        checksum = (hex_bytes_sum + 1) % 256
        line_bytes.append(f":{check}{checksum:02X}")
        
    chkfile = base + "_chk.hex"
    print(f"Checked file: {chkfile}")

    with open(chkfile, "w") as chk_f:
        for line in line_bytes:
            print(line, end='\n', file=chk_f)

print("Done!")

