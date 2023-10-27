#!/bin/sh
# revised listing
# asl should reside in parent directory, otherwise adapt commands
# use './build.sh NIBLFP' to build the binary, emulation by uncomment line 6
fn=$1
#defs="-D EMULA"
../asl -cpu sc/mp ${defs} -L ${fn}.asm &&
../p2bin ${fn} -r '53248-$' &&
../p2hex ${fn} -r '53248-$' -F Intel -l 32 &&
rm ${fn}.p
