#!/bin/sh
# revised listing
# expects asl in parent directory, otherwise adapt
# asl resides in parent directory
../asl -cpu sc/mp -L NIBLE.asm &&
../p2bin NIBLE -r '4096-$' &&
../p2hex NIBLE -r '4096-$' -F Intel -l 32 &&
rm NIBLE.p


