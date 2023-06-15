#!/bin/sh
# revised listing
# asl should reside in parent directory
../asl -cpu sc/mp -L NIBLFP.asm &&
../p2bin NIBLFP -r '53248-$' &&
rm NIBLFP.p

