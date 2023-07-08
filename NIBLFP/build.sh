#!/bin/sh
# revised listing
# asl should reside in parent directory, otherwise adapt commands
../asl -cpu sc/mp -L NIBLFP.asm &&
../p2bin NIBLFP -r '53248-$' &&
../p2hex NIBLFP -r '53248-$' -F Intel -l 32 &&
rm NIBLFP.p

