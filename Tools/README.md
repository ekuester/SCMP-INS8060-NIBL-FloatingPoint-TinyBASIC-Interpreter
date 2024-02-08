## Available tools

 1 convert_hex2bin.py<br>
converts hexadecimal dump into binary file<br>
structure of hexadecimal line: address ; 32 chars consisting of 0..9, A..F<br>
example: `D000;C40C3FD500C41CDC0135C40031C400C9`

 2 disass4scmp.py<br>
converts (disassembles) binary file into SC/MP mnemonics

 3 view_keywords.py<br>
shows table of keywords; keyword is string terminated by byte with bit 7 set, terminated by several '\0' chars

 4 view_tokens.py<br>
shows table of tokens consisting of dictionary ( 1-byte-token, which replaces the following string terminated by byte with bit 7 set )

 5 view_il_table.py<br>
shows table of interpretative language at D802 terminated by double zero bytes

 6 name_labels.py
converts list of address labels into named labels ( default file name for named labels file is 'names_dict.json' ).

 7 concatenate_label_lists.py<br>
concatenates label lists to a big one ( default file name for big label file is 'names_merged.json' ).

 8 decode_listings.sh<br>

 9 combine_files.py<br>
loads binary files into scmp address space  ( here simulated by memory ).

10 reverse_symbols.py<br>
splits an assembler generated symbol table and transforms that into a reversed dictionary.

11 bin2c.py<br>
converts binary into include file for c program, so one can compile it into an emulator, for instance.

12 check_Intel_HEX.py<br>
calculates new checksums for a file in Intel HEX format.

13 bin2Intel_HEX.py<br>
converts binary content of a file into Intel HEX format, so that it can be read into an emulator, for instance.

14 niblcvt.py<br>
converts NIBL BASIC file into NIBL page memory

15 dcm_6502.py<br>
converts a floating point decimal number into a 4 byte floating point representation to be used in NIBLFP


