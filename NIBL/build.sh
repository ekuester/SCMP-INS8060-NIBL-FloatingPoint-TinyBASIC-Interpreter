#!/bin/sh
# revised listing, compiles without scmp2asl
# asl resides in parent directory
../asl -cpu sc/mp -L nibl_19761217.asm &&
../p2bin nibl_19761217 -r '$-$' &&
mv nibl_19761217.bin NIBL.bin &&
mv nibl_19761217.lst NIBL.lst &&
rm nibl_19761217.p
