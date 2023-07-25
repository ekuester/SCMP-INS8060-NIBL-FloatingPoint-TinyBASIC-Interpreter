#!/bin/bash
# reconstruct floating point basic by Erich Küster
# national semiconductor ins8060 aka sc/mp 1976
# from hexdump to disassembled listing

# convert hex to bin files
$ ./1_convert_hex2bin.py
# disassemble individual files normally and generate label json file
$ ./2_disass4scmp.py D000 D000 > D000.dsm
$ ./2_disass4scmp.py D400 D400 > D400.dsm
$ ./2_disass4scmp.py D45C D45C > D45C.dsm
$ ./2_disass4scmp.py D4C0 D4C0 > D4C0.dsm
$ ./2_disass4scmp.py D500 D500 > D500.dsm
$ ./2_disass4scmp.py D5CE D5CE > D5CE.dsm
$ ./2_disass4scmp.py DFC1 DFC1 > DFC1.dsm
# decode special cases
# keyword table
$ ./3_view_keywords.py D610 D610 > D610.words
# token table
$ ./4_view_tokens.py D6A0 D6A0 > D6A0.token
# i.l. table part 1
$ ./5_view_il_table.py D802 D802 > D802.il1
# i.l. table part 2
$ ./5_view_il_table.py DB00 DB00 > DB00.il2
# check D000, D45C, DFC1 .json files for labels < D000
# view binary file as table with 2-byte hexadecimals
$ od -v -Ax -t x1 NIBL.bin > NIBL.hex
# revert hex dump listing to binary
# replace all linefeeds with spaces
# insert a new line after every 48 chars
$ sed -i 's/.\{48\}/&\
/g' [filename].hex
# the new line in the command is essential !
# now convert hexdump into binary
$ xxd -r -p 6502.hex 6502.bin

