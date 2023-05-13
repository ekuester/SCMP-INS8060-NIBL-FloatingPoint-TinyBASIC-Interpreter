#!/usr/bin/env python3
# show table of tokens
# dictionary: 1-byte-token, which replace string terminated by byte with bit 8 set
# terminated by double zero bytes
# usage: ./4_view_tokens.py basefilename startaddress

import binascii
import sys

base = sys.argv[1]
address = int(sys.argv[2],16)
binfile = base + ".bin"
print(f"binfile: {binfile}")

with open(binfile, "rb") as f:
    while (byte := f.read(1)):
        # Do stuff with byte
        code = byte[0]
        print(f"{address:4X} {code:2X}", end='')
        address +=1
        if byte == b'\x00': break
        finished = False
        command = ""
        while not finished:
            byte = f.read(1)
            address +=1
            code = byte[0]
            if code > 128:
                code = code - 128
                command = command + chr(code)
                print(f" : {command}")
                finished = True
            else:
                command = command + chr(code)
f.close()
print()
print("Done!")

