#!/usr/bin/env python3
# SC/MP tools
# split symbol table and put into a reversed dictionary
# Erich Küster, Krefeld / Germany May 2023

import json, os, sys

name = "symbol_table.tmp"
symbols = {}
with open(name, "rb") as bin_f:
   file_lines = bin_f.readlines()
for line in file_lines:
    fields = line.split()
    key = fields[1].decode('ASCII')
    value = fields[0].decode('ASCII')
    symbols[key] = value
symbols_name = "symbol_table.json"
with open(symbols_name, "w") as json_f:
    json_f.write(json.dumps(symbols))
print("νενικήκαμεν")
