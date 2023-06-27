@ECHO OFF
REM revised listing
asl -cpu sc/mp -L NIBLFP.asm
IF ERRORLEVEL 1 GOTO error
p2bin NIBLFP -r 53248-$
p2hex NIBLFP -r 53248-$ -F Intel -l 32
IF ERRORLEVEL 1 GOTO error
del>NUL NIBLFP.p
IF NOT ERRORLEVEL 1 GOTO done

:error
echo ERROR while building!

:done
