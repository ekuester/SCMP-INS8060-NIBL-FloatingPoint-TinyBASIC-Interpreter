#!/usr/bin/env python3
# show table of keywords
# keyword is string terminated by byte with bit 7 set
# terminated by several '0' chars
# usage: ./4_view_keywords.py basefilename startaddress

import binascii
import sys

base = sys.argv[1]
address = int(sys.argv[2],16)
binfile = base + ".bin"
print(f"binfile: {binfile}")

with open(binfile, "rb") as f:
    while (byte := f.read(1)):
        if byte != b'0': break
        address +=1
    finished = False
    while not finished:
        keyword = ""
        more = True
        print(f"{address:4X} : ", end='')
        while more:
            code = byte[0]
            if code > 128:
                more = False
                code = code - 128
                keyword = keyword + chr(code)
                print(f"{keyword}")
            else:
                keyword = keyword + chr(code)
            byte = f.read(1)
            address +=1
            if byte == b'0' :
                finished = True
f.close()
print()
print("Done!")

