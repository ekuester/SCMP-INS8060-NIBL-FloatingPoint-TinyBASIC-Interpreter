# BASIC-Interpreter mit Fliesskomma

### Allgemeine Angaben
Der BASIC-Interpreter ist in der jetzigen Version 7.9 etwa 12 kByte lang und belegt den Speicherraum von hex D000 bis FFFF. Die Ansprungaddresse für das Basic ist hex D000 (ursprünglich hex DFC1).

Im Wesentlichen entspricht der Befehlssatz des Basic dem des PET von Commodore, hat natürlich nicht dessen graphische Funktionen und Sonderzeichen, da diese mit dem -wohl allgemein vorhandenen- Elekterminal sowieso nicht verarbeitet werden können, Diese Version übersetzt aber ebenfalls alle Basic-Befehle (die Schlüsselworte) in sogenannte Tokens, d.h. Ein-Syte-Befehle mit dem Code von hex 80 bis CD (siehe
Tabelle). Bereits bei der Eingabe einer Zeile -mit Zeilennummer oder ohne- wird die Übersetzung durchgeführt, wodurch ebenfalls wertvoller Speicherplatz in den zur Programmabspeicherung verwendeten "Pages" gespart wird. Die Übersetzung braucht natürlich Zeit, bedingt dadurch werden Befehle, die ohne führende Zeilennummer im "direct mode" eingegeben werden, etwas langsamer ausgeführt. Dieser Nachteil, wenn
es Überhaupt einer ist, wird dann durch die schnellere Abarbeitung der Basic-Befehle während des "run mode" wieder wett gemacht, Bei der Beurteilung der Geschwindigkeit muB allerdings berücksichtigt werden, daB Rechnungen mit FlieBkommazahlen wegen des höheren "Bytebedarfs" länger als Festkommaoperationen dauern.

Es können die vier Grundrechenarten sowie die Potenzierung ** (wird intern in ^ übersetzt und erscheint bei einem nachfolgenden LIST so) mit ganzen Zahlen und Fließkommazahlen durchgeführt werden, die betragsmäßig zwischen 10 hoch -39 und 10 hoch 38 liegen dürfen. Weiterhin existieren die beiden Operatoren DIV (dividiert zwei Zahlen durcheinander und schneidet die Nachkommastellen ab) und MOD (berechnet den Divisionsrest: 11 MOD 3 = 2).

Der Grundsatz "Punktrechnung geht vor Strichrechnung" wird strikt beachtet, es sei denn man verwendet Klammern, wodurch jede beliebige Verarbeitung möglich wird (maximal fünf Klammerebenen).

Bei der Eingabe oder in Statements können die Zahlen in normaler Darstellung (z.B. 12.34) oder in Exponentialdarstellung (z.B. 1234.56E-12) geschrieben werden. Zahlen, die betragsmäßig größer sind als 8,388, 607 (2 hoch 23 -1) sind, müssen allerdings **immer** in Exponentialdarstellung geschrieben werden. Es wird generell mit einer Genauigkeit von höchstens 6 signifikanten Stellen gerechnet, bei den trigonometrischen Funktionen COS, SIN, TAN sowie ATN (Arkustangens) kann die Genauigkeit manchmal auch nur 3 bis 4 Stellen betragen. Es sei darauf hingewiesen, daB das Argument der triganometrischen Funktionen im Bogenmaß eingegeben werden muB. Es können drei Logarithmus-Funktionen LB, LG und LN verwendet werden, die jeweils den Logarithmus zur Basis 2, 10 bzw. e (Euler'sche Zahl) berechnen.

Mit Hilfe des PAGE-Befehls kann in gewohnter Weise wie beim NIBL die Seite gewechselt werden. Im Gegensatz zum NIBL bzw. NIBLE, das in jedem Fall den nächsten Basic-Befehl vom Änfang der neuen Seite holt, wird in dieser Version geprüft, ob in derselben Zeile ein GOTO-oder GOSUB-Befehl steht. Ist dies der Fall, wird zu der entsprechenden Zeile in der neuen Seite verzweigt.

