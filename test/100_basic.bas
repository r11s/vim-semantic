10 REM -------------------------------------------------------------
20 REM Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
30 REM Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
40 REM Klassisches BASIC mit Zeilennummern.  Starten: bwbasic 100_basic.bas  (Bywater BASIC; stdin leer, z. B. echo | bwbasic ...)
50 REM (BASIC kennt weder Klassen noch Ausnahmen: Fehler = Flag V)
60 REM -------------------------------------------------------------
100 REM Konstanten
110 LET PI = 3.141592653589793
120 LET EP = 1E-9
130 LET MS = 50
140 DIM K(4), A(4), B(4), C(4), F(4), L(4)
150 DIM N$(3)
160 LET N$(1) = "Kreis" : LET N$(2) = "Rechteck" : LET N$(3) = "Dreieck"
200 PRINT "Formen-Rechner"
210 REM Art: 1 Kreis, 2 Rechteck, 3 Dreieck
220 DATA 1, 2.5, 0, 0
230 DATA 2, 4.0, 3.0, 0
240 DATA 3, 3.0, 4.0, 5.0
250 DATA 3, 1.0, 2.0, 10.0
260 REM TODO: weitere Formen
270 LET G = 0
280 FOR I = 1 TO 4
290 READ K(I), A(I), B(I), C(I)
300 GOSUB 2000
310 IF V = 1 THEN 340
320 LET G = G + 1 : LET L(G) = I
330 GOTO 400
340 REM ungueltige Form melden
350 PRINT "Fehler: "; N$(K(I)); " ";
360 LET X = A(I) : LET D = 1 : GOSUB 3000 : PRINT F$;
370 IF K(I) > 1 THEN LET X = B(I) : GOSUB 3000 : PRINT "/"; F$;
380 IF K(I) > 2 THEN LET X = C(I) : GOSUB 3000 : PRINT "/"; F$;
390 PRINT " ungueltig"
400 NEXT I
410 REM Flaechen berechnen
420 FOR J = 1 TO G
430 LET I = L(J) : GOSUB 2200 : LET F(I) = R
440 NEXT J
450 REM Sortieren nach Flaeche (Bubblesort ueber L)
460 FOR P = 1 TO G - 1
470 FOR J = 1 TO G - P
480 IF F(L(J)) <= F(L(J + 1)) THEN 510
490 LET T = L(J) : LET L(J) = L(J + 1) : LET L(J + 1) = T
510 NEXT J
520 NEXT P
530 FOR J = 1 TO G
540 LET I = L(J)
550 PRINT N$(K(I)); ": Flaeche=";
560 LET X = F(I) : LET D = 2 : GOSUB 3000 : PRINT F$; " Umfang=";
570 GOSUB 2400 : LET X = R : GOSUB 3000 : PRINT F$; " ";
580 LET S$ = "klein"
585 IF F(I) >= 10.0 THEN LET S$ = "gross"
587 PRINT S$;
590 LET E = 0 : IF K(I) = 2 THEN LET E = 4
600 IF K(I) = 3 THEN LET E = 3
610 PRINT " Ecken="; MID$(STR$(E), 2)
620 NEXT J
630 LET X = 48 : LET Y = 18 : GOSUB 2600
640 PRINT "ggT(48, 18) = "; MID$(STR$(X), 2)
650 PRINT "Primzahlen bis 30:";
660 FOR Q = 2 TO 30
670 LET X = Q : GOSUB 2800
680 IF V = 1 THEN PRINT " "; MID$(STR$(Q), 2);
690 NEXT Q
700 PRINT
710 LET X = 2 : GOSUB 1000
720 LET X = W : LET D = 8 : GOSUB 3000
730 PRINT "Wurzel(2) = "; F$
740 REM Maske: 255 AND 170 bitweise ueber 8 Bits
750 LET M = 0 : LET U = 255 : LET Y = 170 : LET H = 1
760 FOR Q = 1 TO 8
770 IF (U - INT(U / 2) * 2) = 1 AND (Y - INT(Y / 2) * 2) = 1 THEN LET M = M + H
780 LET U = INT(U / 2) : LET Y = INT(Y / 2) : LET H = H * 2
790 NEXT Q
800 PRINT "Maske: "; MID$(STR$(M), 2)
810 PRINT "Skala: "; MID$(STR$(INT(1000000 / 8)), 2)
820 SYSTEM
1000 REM --- WURZEL: Quadratwurzel von X nach Newton -> W
1010 LET W = 0
1020 IF X <= 0 THEN RETURN
1030 LET W = X
1040 FOR Z = 1 TO MS
1050 LET NW = 0.5 * (W + X / W)
1060 LET DF = NW - W
1070 IF DF < 0 THEN LET DF = -DF
1080 LET W = NW
1090 IF DF < EP THEN RETURN
1100 NEXT Z
1110 RETURN
2000 REM --- Pruefen der Form I -> V (1 = ungueltig)
2010 LET V = 0
2020 IF K(I) = 1 AND A(I) <= 0 THEN LET V = 1
2030 IF K(I) = 2 AND (A(I) <= 0 OR B(I) <= 0) THEN LET V = 1
2040 IF K(I) <> 3 THEN RETURN
2050 IF A(I) + B(I) <= C(I) THEN LET V = 1
2060 IF A(I) + C(I) <= B(I) THEN LET V = 1
2070 IF B(I) + C(I) <= A(I) THEN LET V = 1
2080 RETURN
2200 REM --- Flaeche der Form I -> R
2210 IF K(I) = 1 THEN LET R = PI * A(I) * A(I) : RETURN
2220 IF K(I) = 2 THEN LET R = A(I) * B(I) : RETURN
2230 LET S = (A(I) + B(I) + C(I)) / 2
2240 LET X = S * (S - A(I)) * (S - B(I)) * (S - C(I))
2250 GOSUB 1000 : LET R = W
2260 RETURN
2400 REM --- Umfang der Form I -> R
2410 IF K(I) = 1 THEN LET R = 2 * PI * A(I) : RETURN
2420 IF K(I) = 2 THEN LET R = 2 * (A(I) + B(I)) : RETURN
2430 LET R = A(I) + B(I) + C(I)
2440 RETURN
2600 REM --- GGT: groesster gemeinsamer Teiler von X und Y -> X
2610 IF Y = 0 THEN RETURN
2620 LET T = X - INT(X / Y) * Y
2630 LET X = Y : LET Y = T
2640 GOTO 2610
2800 REM --- Primzahltest X -> V (1 = Primzahl)
2810 LET V = 1
2820 IF X < 2 THEN LET V = 0 : RETURN
2830 LET T = 2
2840 IF T * T > X THEN RETURN
2850 IF X - INT(X / T) * T = 0 THEN LET V = 0 : RETURN
2860 LET T = T + 1
2870 GOTO 2840
3000 REM --- Zahl X mit D Nachkommastellen -> F$
3010 LET SK = 10 ^ D
3020 LET WT = INT(X * SK + 0.5)
3030 LET IP = INT(WT / SK)
3040 LET RS = WT - IP * SK
3050 LET R$ = MID$(STR$(RS), 2)
3060 IF LEN(R$) < D THEN LET R$ = "0" + R$ : GOTO 3060
3070 LET F$ = MID$(STR$(IP), 2) + "." + R$
3080 RETURN
