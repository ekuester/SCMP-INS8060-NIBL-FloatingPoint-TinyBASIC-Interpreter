#!/bin/sh
# revised listing
# asl should reside in parent directory, otherwise adapt commands
../asl -cpu sc/mp -L MONITOR.asm &&
../p2bin MONITOR -r '49152-$' &&
../p2hex MONITOR -r '49152-$'  -F Intel -l 32 &&
rm MONITOR.p
