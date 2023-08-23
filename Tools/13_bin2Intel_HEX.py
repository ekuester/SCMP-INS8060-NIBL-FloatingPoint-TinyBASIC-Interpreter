#!/usr/bin/env python3
# converts binary into Intel HEX file
# so one can read it in e.g. into an emulator
# bin2Intel_HEX.py

import binascii
import re, os, sys

def usage():
    print("converts binary into into Intel HEX file,")
    print("so one can read it in e.g. into an emulator")
    print("usage: ./bin2Intel_HEX.py [binary file] [hex start address] [bytes pro line]")
    print("give binary without .bin extension")
    print("example: bin2Intel_HEX kalenda 1000 32")
    print("Erich Küster, Krefeld/Germany August 2023")
    quit()

argc = len(sys.argv)
if argc == 1 or argc > 4:
    usage()
base = sys.argv[1]
start = 0
if argc > 2:
    start = int(sys.argv[2],16)
if argc == 4:
    byte_count = int(sys.argv[3],10)
else:
    byte_count = 16
print(start, byte_count)
bin_file = base + ".bin"
file_stats = os.stat(bin_file)
file_size = file_stats.st_size
print(f'Will read file {bin_file} with {file_size} Bytes')
# read binary into bytearray
# read binary into bytearray
with open(bin_file, "rb") as bin_f:
    b_bytes = bytes(bin_f.read())
# split into chunks of byte_count length
chunks = [b_bytes[i:i + byte_count] for i in range(0, len(b_bytes))]
hex_lines = []
for a, chunk in enumerate(chunks):
    address = start + a
    if  not (a % byte_count):
        hex_bytes = binascii.hexlify(chunk).decode('ASCII')
        hex_line = f":{byte_count:02X}{address:04X}00{hex_bytes}00"
        hex_lines.append(hex_line)
line_bytes = []
for line in hex_lines:
    # there is no line feed
    check = line[1:-2]
    hex_bytes = binascii.unhexlify(check)
    hex_bytes_sum = sum(hex_bytes)
    # one's complement
    hex_bytes_sum ^= 0xFF
    # add one for two's complement
    checksum = (hex_bytes_sum + 1) % 256
    line_bytes.append(f":{check}{checksum:02X}")

hexfile = base + ".hex"
print(f"Generated file: {hexfile}")
with open(hexfile, "w") as hex_f:
    for line in line_bytes:
        print(line, end='\n', file=hex_f)
print("Done!")

