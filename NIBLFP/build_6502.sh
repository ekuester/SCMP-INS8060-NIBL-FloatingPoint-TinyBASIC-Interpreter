#!/bin/sh
# revised listing
# asl should reside in parent directory
../asl -cpu 6502 -L 6502FP.asm &&
../p2bin 6502FP -r '7424-$' &&
rm 6502FP.p

