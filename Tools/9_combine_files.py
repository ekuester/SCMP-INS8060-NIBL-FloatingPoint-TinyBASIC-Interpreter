#!/usr/bin/env python3
# SC/MP tools
# load bin files into scmp address space simulated by memory
# Erich Küster, Krefeld / Germany April 2023

import binascii
import json, os, sys

def usage():
    print("SC/MP tools:")
    print("Load .bin files into scmp simulated address space")
    print("Erich Küster, Krefeld / Germany")
    print("Usage: ./9_combine_files file name ...")
    print("Example: ./9_combine_files.py D000 D400 D45B D4C0 D500 D5CE D610 D6A0 D802 DB00 DFC1")
    print("give file names without .bin extension, default output is 'memory.snap'")
    quit()

argc = len(sys.argv)
print(argc)
if (argc == 1):
    usage()
file_starts = []
file_names = []
# skip first argument (is program name)
for file_count, file in enumerate(sys.argv[1:]):
    file_starts.append(file)
    file_name = file + ".bin"
    print(f" {file_count} : {file_name}")
    file_names.append(file_name)
scmp_memory = bytearray([0xff] * 65536)
end = argc - 1
file_range = range(0, end)
for name, start in zip(file_names, file_starts):
    file_stats = os.stat(name)
    with open(name, "rb") as bin_f:
        file_bytes = bytes(bin_f.read())
    load = int(start, 16)
    # now copy the program bytes into scmp memory beginning at load
    for i, byte in enumerate(file_bytes):
        scmp_memory[load + i] = byte
    print(f'read file {name} with {file_stats.st_size} Bytes to location {load:04X}')
    print(f'{i} bytes copied')
# snapshot scmp memory
snapshot = "scmp_memory.snap"
with open(snapshot, "wb") as snap_f:
    snap_f.write(scmp_memory)
# special case: generate binary code for eproms
# slice bytearray at 0xd000
scmp_tail = scmp_memory[0xD000:]
snapshot = "scmp_tail.snap"
with open(snapshot, "wb") as snap_f:
    snap_f.write(scmp_tail)
# generate hex listing
begin = 0xD000
lines = []
byte_range = range(0xD000, 0x10000, 16)
for b in byte_range:
    line = f'{b:04X}:'
    for i in range(16):
        index = b + i
        line += f' {scmp_memory[index]:02X}'
    line += '\n'
    lines.append(line)
hex_file_name = "D000-FFFF.hex"
with open(hex_file_name, "w") as hex_f:
    hex_f.writelines(lines)
        
print("νενικήκαμεν")
