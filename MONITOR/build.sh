#!/bin/sh
# revised listing
# asl should reside in parent directory, otherwise adapt commands
# use './build.sh NIBLFP' to build the binary, for emulation uncomment line 6
fn=$1
#defs="-D EMULA"
../asl -cpu sc/mp ${defs} -L ${fn}.asm &&
../p2bin ${fn} -r '49152-$' &&
../p2hex ${fn} -r '49152-$'  -F Intel -l 32 &&
rm ${fn}.p
