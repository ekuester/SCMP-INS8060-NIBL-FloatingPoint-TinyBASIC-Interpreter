#!/bin/sh
# revised listing, compiles without scmp2asl
# asl resides in parent directory
../asl -cpu sc/mp -L NIBLFP.asm &&
../p2bin NIBLFP -r '53248-$' &&
rm NIBLFP.p

