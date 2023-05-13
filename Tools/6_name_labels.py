#!/usr/bin/env python3
# convert list of address labels into named labels
# default file name for named labels file is 'names_dict.json'

import json, re, sys

def usage():
    print("opens label file of disassembled code")
    print("and assigns each label a meaningful name")
    print("first line gives start address")
    print("usage: ./6_name_labels.py json_file")
    print("give json_file without .json extension")
    print("Erich Küster April 2023")
    quit()

argc = len(sys.argv)
if argc == 1 or argc > 2:
    usage()
base = sys.argv[1]
# labels file
labels_file = base + '.json'
# named labels file
names_file = 'names_dict.json'
inp_len = 0
while not inp_len:
    prompt = '[d]elete, [m]odify, [n]ew entry: '
    choice = input(prompt).lower()
    if not re.match(r"^[dmn]+$", choice):
        continue
    inp_len = len(choice)

with open(labels_file, 'r') as labels_f, open (names_file, 'r') as names_f:
    labels = json.load(labels_f)
    names = json.load(names_f)

for label in labels:
    prompt = f'{label}: '
    if label in names.keys():
        # in the moment skip editing process
        continue
    ends = False
    # input name for label without whitespaces
    while True:
        name = input(prompt).upper()
        if not name:
            # empty string ends input
            ends = True
            break
        if not re.match(r"^\S+$", name):
            # no whitespaces allowed
            print('repeat^')
            continue
        else:
            break
    if ends:
        if not names:
            quit()
        else:
            break
    # limit name to six chars
    names[label] = f'{name[:6]}'
    line = prompt + name
    print(f'{line} stored')
with open ('names_real.json', 'w') as json_f:
    json_f.write(json.dumps(names))
print("Done!")
'''
if not re.match(r"^[A-Fa-f0-9]+$", line):
    print('repeat^')
print(labels, names)
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

'''

