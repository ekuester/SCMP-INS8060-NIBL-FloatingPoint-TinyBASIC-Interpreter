#!/bin/sh
# revised listing
# asl should reside in parent directory, otherwise adapt commands
# use './build.sh NIBLFP' to build the binary, emulation by uncomment line 8 or line 9
fn=$1
#defs="-D USETTY"
#defs="-D USETTY -D INTERNAL"
#defs="-D EMULA"
defs="-D EMULA -D INTERNAL"
#defs="-D KBPLUS"
../asl -cpu sc/mp ${defs} -L ${fn}.asm &&
../p2bin ${fn} -r '53248-$' &&
../p2hex ${fn} -r '53248-$' -F Intel -l 32 &&
rm ${fn}.p

