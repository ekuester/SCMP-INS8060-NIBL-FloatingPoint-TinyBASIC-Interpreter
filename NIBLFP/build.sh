#!/bin/sh
# revised listing
# asl should reside in parent directory, otherwise adapt commands
fn=NIBLFP
defs="-D BAUD=1200"
#defs="-D EMULA"
../asl -cpu sc/mp ${defs} -L ${fn}.asm &&
../p2bin ${fn} -r '53248-$' &&
../p2hex ${fn} -r '53248-$' -F Intel -l 32 &&
rm ${fn}.p

