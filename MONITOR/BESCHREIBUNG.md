### MONTORPROGRAMM (Entstehungsjahr etwa 1982)

### A. Erläuterungen zum Listing

1 Das Monitorprogramm arbeitet mit einer Art "Interpretative Language", wie sie
auch im NIBL-BASIC verwendet wird. In dieser Version werden die ersten beiden
Bits des "high byte" der Addresse zur Dekodierung bestimmter Routinen verwendet.
Bedingt dadurch kann das Monitor—Programm ohne größere Anderungen nur auf den
Seiten C,D,E,F laufen. Durch Umstellen des Bereichs hex C03e bis C05a ist jedoch
prinzipiell ein Verlegen des Monitors in jede Seite möglich.

Befehle:

`DO      high byte Addresse 11xx xxxx`
-    eine Subroutine wird beginnend mit der angegebenen Addresse ausgeführt;
    Subroutinen muissen mit hex 3f00 abgeschlossen werden.

Beispiel: `C580 DO GETASC` -> führt Routine ab hex c580 aus (ein Zeichen von
der ASCII-Tastatur wird eingelesen).

`TSTSTR  high byte Addresse 10xx xxx`
-    testet ein mit getasc eingelesenes Zeichen gegen den dem tst-Befehl nachfolgenden String. Falls Ubereinstimmung mit dem ersten Zeichen der Textkette besteht, wird der String ausgegeben und der nächste folgende Befehl
bearbeitet. Andernfalls wird das Programm an der vom .tst—Befehl angegebenen Stelle weiter bearbeitet.
Beispiel:</br>
```
          80e8 tst list
          474F 'go!
          54cf ‘to!
```
Falls eingelesenes Zeichen ein g ist, wird GOTO auf dem Bildschirm ausgegeben, falls nicht, wird der n&chste Befehl an der Stelle hex C0E8 interpretiert,

`GOTO     high byte Addresse 01xx xxxx`
-    Das Programm springt zur angegebenen Addresse und bearbeitet den dort vorgefundenen Befehl.

`END`    Ein-Byte-Befehl mit Kode 0000 0000
-    Nachfolgende Befehle werden als Maschinenprogramm interpretiert, bei Auftreten von hex 3f00 springt das Programm in die Kommandoschleife.

2 Innerhalb eines Maschinenprogramms können Unterprogramme durch `3F ABCD` ==> CALL $ABCD aufgerufen werden, wobei $ABCD die Addresse des Unterprogramms ist.</br>
Die Rückkehr ins aufrufende Programm erfolgt auch hier durch hex 3F00.
Ein Schreiben auf dem Bildschirm z.B. ist durch folgendes einfaches Programm möglich, wobei man volle Cursor—Kontrolle hat:
```
    0C00 3FC580 LOOP: CALL GETASC
    0C03 3FC700       CALL PUTASC
    0C06 90F8         JMP LOOP
```

3 Zur Abspeicherung von Daten benötigt das Monitorprogramm mindestens 1/2k RAM in einer beliebigen Seite, wobei Pointer 2 des SC/MP als RAM-Pointer geladen wird, In dieser Version ist das ein Bereich von hex OE00 bis OFFF und Pointer 2 wird also mit OF80 geladen werden (siehe Programmaddressen hex C002 bis C008).

4 Für eine Verlegung des Monitors in eine andere Seite müssen alle do, tst, gto und call Befehle ge&ndert werden. Weiterhin muB Pointer 3 mit hex x080 geladen werden, wobei x die Seitennummer ist (siehe Programmaddressen hex c00f bis c011).
Beispiele:</br>
```
               C       D       E       F  <= Seite
          do getasc   c580    d580    e580    f580
          tst list    80e8    90e8    a0e8    bOe8
          gto mdfy1   426e    526e    626e    726e
          call putasc 3fc700  3fd700  3fe700  3ff700
```

### B. Befehle des Monitors

1) Der Monitor wird aktiviert, indem man den Programmcounter des SC/MP auf
hex COOO setzt (mit Hilfe von ELBUG durch RUN COOO oder im NIBL durch LINK
C000 cr). Der Monitor meldet sich mit
 MONITOR
* _
* bedeutet immer Bereitschaft zur Eingabe eines Kommandos durch Drücken einer
Taste der ASCTI—Tastatur</br>
( B=BLOCK TRANSFER, C=CASSETTE, G=GOTO, I=INTERPRETER, L=sLIST, M=MODIFY, P=PROGRAM, D=DISASSEMBLE )
? bedeutet immer Bereitschaft zur Annnahme einer Hexadezimalzahl mit 1 bis 4
Stellen. Die Eingabe wird mit CR (ASCII OD) abgeschlossen, mit Ausnahme bei der
Eingabe von vier Hex—Zeichen, bei der automatisch CR gesetzt wird, wodurch bei
MODIFY eine fortlaufende Eingabe ermöglicht wird. Jede Eingabe kann durch Control
C (ASCII 03) unterbrochen werden, wobei eine BREAK-Meldung an den Bildschirm
abgesetzt wird und das Programm in die Kommandoschleife springt.

2) MODIFY - aktiviert mit Taste M
MONITOR
* MODIFY ? _
Das System erwartet eine Startadresse aus 1 bis 4 Hex—Zeichen; nach Eingabe wird
die Startadresse und ihr Inhalt ausgegeben,.
Jetzt stehen drei Möglichkeiten zur Auswahl:
a) Taste CR: Nächsthöherer Speicherplatz wird angezeigt.
b) Taste LF (ASCII OA): Nächsttieferer Speicherplatz wird angezeigt.
c) Eingabe einer Hexadezimalzahl: der (die) entsprechende(n) Speicherplatz(plätze)
wird (werden) verändert und der nächste Speicherplatz mit Inhalt angezeigt.
Falls keine Änderung möglich ist, weil an dieser Stelle z.B. ein PROM liegt,
erscheint RAM ERROR auf dem Bildschirm. Bei Eingabe einer falschen Hex—Zahl
wird HEX ERROR ausgegeben.

3) LIST - aktiviert durch Taste L
listet 16x16 Bytes ab der Startadresse als Matrix. AnschlieBendes Drücken der
Taste CR liefert weitere 16x16 Bytes, Drücken der Taste LF liefert 1x16 Bytes
(1 Zeile). Beliebige andere Taste erzeugt BREAK.

4) GOTO - aktiviert durch G
springt die einzugebende Adresse an und beginnt mit der Ausführung des dort
stehenden Maschinenprogramms (entspricht RUN bei ELBUG und LINK beim NIBL).

5) BLOCK TRANSFER - aktiviert durch B
 ANFAD= ?
 ENDAD= ?
 NEWAD= ?
erwartet zunächst Eingabe der Anfangsadresse des Blocks, dann die Endadresse
(falls Endadresse kleiner als Anfangsadresse erscheint BLK ERROR). AnschlieBend
gibt man die neue Adresse ein, auf die der Block verschoben werden soll. Es ist
mdglich, nur einen Speicherplatz zu schieben, es kann auch Uber die Seitengrenzen
geschoben werden.

6) CASSETTE - aktiviert durch C
Auf dem Bildschirm erscheint SELECT: D=DUMP/L=LOAD/S=SPEED. Nach Drücken der ent—
sprechenden Taste wird bei DUMP ein Speicherblock von ANFAD bis ENDAD an die Cassette
ausgegeben, waéhrend LOAD von der Cassette ladt. Dabei hat man zwei Möglichkeiten:
Laden in den Speicherbereich, der auf dem Band bei der DUMP-Operation gespeichert
wird (Taste L und danach Taste VT (hex 0b, Control K) oder Laden in einen anderen
Speicherbereich (Taste L und danach beliebige andere Taste auBer VT oder ETX (hex 03,
Control C); es erscheint ANFAD= ? und danach ENDAD= ?).
Die Ubertragungsgeschwindigkeit kann mit S(=SPEED) veréndert werden; verändert man
die Geschwindigkeit nicht, wird mit 600 Baud ausgegeben und geladen (fest eingestelltes
Speedbyte sitzt auf x457 — für eigene Werte).
Die Cassettenroutinen arbeiten mit dem Elektor—Cassetten—Interface und sind kompatibel
mit den Elbug-Routinen bzw. mit den Basic-Cassetten—Routinen.

7) DISASSEMBLE ~ aktiviert durch D
disassembliert den Speicherinhalt ab der einzugebenden Addresse. Durch Drücken der
BREAK—Taste werden weitere Zeilen ausgegeben, Ein Verlassen ist nur mit RESET mGglich.

8) Interpreter - aktiviert durch I
springt einen vorhandenen Basic-Interpreter an. Die Ansprungaddresse minus eins muB
an den Speicherplétzen hex x5e3 (low byte) bzw. hex x5e6 (high byte) abgespeichert
sein, Bei Lieferung steht dort c0 bzw. df = hex dfc0.

9) PROGRAM - aktiviert durch P
dient zur Programmierung von 5V — Eproms 2758, 2716 und 2732. Vorhanden sein muB die
Homecomputer 48-I/O-Lines—Karte mit 2x8255 und die Programmierplatine für 2758/2716,
die im Falle der 2732 laut beiliegendem Schaltplan modifiziert werden muß.
Die Routine erwartet nach Aktivierung die Angabe des Eprom—Typs und gibt dann ein
kurzes Menü aus: C=CHECK/L=LIST/T=TRANSFER. Mit CHECK wird der Löschzustand des Eproms
geprüft, bei O.K. sind alle Bytes auf hex FF, ansonsten ERASE ERROR mit Angabe der
ersten aufgefundenen, nicht gelöschten Speicherstelle. L=LIST listet den Inhalt des
Eproms in 16x16 Bytes-Blöcken aus, ein neuer Block wird durch CR (hex 0D) ausgegeben.
TRANSFER übergibt einen Speicherbereich von ANFAD bis ENDAD an das Eprom, Wenn NEWAD= ?
erscheint, schaltet man die Programmierspannung an und gibt die Anfangsaddresse sin,
ab der der Speicherbereich im Eprom stehen soll (Beim Eprom 2758 miissen Bit 10-15,
beim 2716 Bit 11-15 und beim 2732 Bit 12-15 der Addresse immer 0 sein!). Falls keine
oder nur unvollstandige Programmierung mdglich ist, kommt PROM ERROR.

10) WRITE ~ aktiviert durch W
Ein beliebiger Text kann unter voller Cursorkontrolle auf dem Bildschirm ausgegeben
werden, Ein Verlassen der Routine ist mit Taste ETX (hex 3, Control C) möglich.

11) FF - aktiviert durch Taste FF (hex 0C, Control L)
löscht den Bildschirm.

