#!/usr/bin/env python3
# converts NIBL BASIC file into NIBL page memory 
# so one can read it into the VARCem emulator
# author of version in C: Fred N. van Kempen, <waltje@varcem.com>
# author of version in python: Erich Kuester <erich.kuester@arcor.de>
# niblcvt.py

#		legal notice
#		Copyright 2023 Fred N. van Kempen.
#
#		Redistribution and  use  in source  and binary forms, with
#		or  without modification, are permitted  provided that the
#		following conditions are met:
#
#		1. Redistributions of  source  code must retain the entire
#		   above notice, this list of conditions and the following
#		   disclaimer.
#
#		2. Redistributions in binary form must reproduce the above
#		   copyright  notice,  this list  of  conditions  and  the
#		   following disclaimer in  the documentation and/or other
#		   materials provided with the distribution.
#
#		3. Neither the  name of the copyright holder nor the names
#		   of  its  contributors may be used to endorse or promote
#		   products  derived from  this  software without specific
#		   prior written permission.
#
# THIS SOFTWARE  IS  PROVIDED BY THE  COPYRIGHT  HOLDERS AND CONTRIBUTORS
# "AS IS" AND  ANY EXPRESS  OR  IMPLIED  WARRANTIES,  INCLUDING, BUT  NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE  ARE  DISCLAIMED. IN  NO  EVENT  SHALL THE COPYRIGHT
# HOLDER OR  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL,  EXEMPLARY,  OR  CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE  GOODS OR SERVICES;  LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED  AND ON  ANY
# THEORY OF  LIABILITY, WHETHER IN  CONTRACT, STRICT  LIABILITY, OR  TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING  IN ANY  WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
import binascii
import re, os, sys

def usage():
    print("converts plain BASIC file into Intel HEX file,")
    print("so one can read it into an emulator, for instance")
    print("usage: ./niblcvt.py [basic file] [hex start address] [bytes pro line]")
    print("give BASIC file without .bas extension")
    print("example: niblcvt calendar 2000 32 (will output calendar.bin and calendar.hex)")
    print("python translation of niblcvt.c by Fred N. van Kempen")
    print("Erich Küster Oktober 2023")
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

bas_file = base + ".bas"
file_stats = os.stat(bas_file)
file_size = file_stats.st_size
print(f'Will read file {bas_file} with {file_size} Bytes')
# read BASIC file into list
b_lines = []
with open(bas_file, "r") as bas_f:
    b_lines = bas_f.readlines()

# Format every line into the page buffer.
# 00 00
# 01 CR
# 02 LINE# H
# 03 LINE# L
# 04 LEN(TEXT)
# 05 TEXT..
# 06 CR
# 07 -1
# 08 -1
# 09 ...

binfile = base + ".bin"
print(f"Memory file: {binfile}")
b_bytes = bytearray()
s_num = ""
# fill page buffer and write file
with open(binfile, "wb") as bin_f:
    b_bytes.extend(b'\0'b'\15')
    bin_f.write(b'\0'b'\15')
    for line in b_lines:
        found = re.search(r'\d+', line)
        if found:
            # fill line buffer
            b_line = bytearray()
            s_num = found.group()
            num = int(s_num, 10)
            b_num = num.to_bytes(2, 'big')
            b_line.extend(b_num)
            l_num = len(s_num)
            # ignore line number and carriage return
            l_line = line[l_num:-1]    
            l_len = len(l_line) + 4
            b_line.extend(l_len.to_bytes(1, 'big'))
            b_line.extend(l_line.encode('ASCII'))
            b_line.extend(b'\15')
            bin_f.write(b_line)
            b_bytes.extend(b_line)
    b_bytes.extend(b'\377'b'\377')
    bin_f.write(b'\377'b'\377')
# build Intel HEX file
# split into chunks of byte_count length
chunks = [b_bytes[i:i + byte_count] for i in range(0, len(b_bytes))]
hex_lines = []
for a, chunk in enumerate(chunks):
    address = start + a
    if not (a % byte_count):
        hex_bytes = binascii.hexlify(chunk).decode('ASCII').upper()
        hex_len = len(hex_bytes) // 2
        hex_line = f":{hex_len:02X}{address:04X}00{hex_bytes}00"
        hex_lines.append(hex_line)
# calculate checksum for each line
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
# write Intel HEX file
hexfile = base + ".hex"
print(f"Memory file: {hexfile}")
with open(hexfile, "w") as hex_f:
    for line in line_bytes:
        print(line, end='\n', file=hex_f)

print("Done!")

