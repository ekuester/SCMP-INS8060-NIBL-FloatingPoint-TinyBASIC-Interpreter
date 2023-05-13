#!/bin/sh
# revised listing, compiles without scmp2asl
# asl resides in parent directory
../asl -cpu sc/mp -L NIBLE.asm &&
../p2bin NIBLE -r '4096-8182' &&
rm NIBLE.p


