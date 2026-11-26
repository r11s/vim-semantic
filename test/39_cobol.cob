>>SOURCE FORMAT FREE
*> ------------------------------------------------------------------
*> Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
*> Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
*> GnuCOBOL.  Bauen und starten: cobc -x -free -o formen 39_cobol.cob && ./formen
*> ------------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. FORMEN.

DATA DIVISION.
WORKING-STORAGE SECTION.
*> Konstanten
01 PI-WERT        COMP-2 VALUE 3.141592653589793.
01 EPS            COMP-2 VALUE 0.000000001.
01 MAX-SCHRITTE   PIC 99 VALUE 50.
01 BYTE-HEX       PIC X VALUE X"FF".
01 BYTE-MASKE     PIC X VALUE X"AA".
01 MASKE          PIC 999.
01 SKALA          PIC 9(6).

*> Formentabelle: Art, Masse, Ergebnisse
01 FORMEN-TABELLE.
   05 FORM OCCURS 4 TIMES.
      10 F-ART      PIC X(8).
      10 F-A        COMP-2.
      10 F-B        COMP-2.
      10 F-C        COMP-2.
      10 F-FLAECHE  COMP-2.
      10 F-UMFANG   COMP-2.
      10 F-ECKEN    PIC 9.
01 TMP-FORM          PIC X(60).
01 ANZAHL            PIC 9 VALUE 0.
01 I                 PIC 99.
01 J                 PIC 99.

*> Hilfsvariablen der Unterprogramme
01 WS-X              COMP-2.
01 WS-ALT            COMP-2.
01 WS-NEU            COMP-2.
01 WS-W              COMP-2.
01 WS-S              COMP-2.
01 WS-GA             PIC 9(4).
01 WS-GB             PIC 9(4).
01 WS-REST           PIC 9(4).
01 WS-N              PIC 9(4).
01 WS-T              PIC 9(4).
01 WS-QUAD           PIC 9(8).
01 WS-GUELTIG        PIC 9.
01 WS-RUND           PIC 9(6)V9(8).
01 WS-RUND1          PIC 9(6)V9.
01 WS-RUND2          PIC 9(6)V99.
01 ED-1              PIC Z(5)9.9.
01 ED-2              PIC Z(5)9.99.
01 ED-8              PIC Z(5)9.99999999.
01 ED-INT            PIC Z(5)9.
01 TXT               PIC X(20).
01 T1                PIC X(20).
01 T2                PIC X(20).
01 T3                PIC X(20).
01 T-FL              PIC X(20).
01 T-UM              PIC X(20).
01 STATUS-TXT        PIC X(5).
01 MELDUNG           PIC X(60).
01 PRIM-TXT          PIC X(80).
01 PRIM-PTR          PIC 99 VALUE 1.

PROCEDURE DIVISION.
HAUPT.
    DISPLAY "Formen-Rechner"
    MOVE "Kreis"    TO F-ART(1)
    MOVE 2.5        TO F-A(1)
    MOVE "Rechteck" TO F-ART(2)
    MOVE 4.0        TO F-A(2)
    MOVE 3.0        TO F-B(2)
    MOVE "Dreieck"  TO F-ART(3)
    MOVE 3.0        TO F-A(3)
    MOVE 4.0        TO F-B(3)
    MOVE 5.0        TO F-C(3)
    MOVE "Dreieck"  TO F-ART(4)      *> TODO: weitere Formen
    MOVE 1.0        TO F-A(4)
    MOVE 2.0        TO F-B(4)
    MOVE 10.0       TO F-C(4)

    PERFORM VARYING I FROM 1 BY 1 UNTIL I > 4
        PERFORM PRUEFE-FORM
        IF WS-GUELTIG = 0
            DISPLAY "Fehler: " FUNCTION TRIM(MELDUNG)
        ELSE
            ADD 1 TO ANZAHL
            MOVE FORM(I) TO FORM(ANZAHL)
            PERFORM BERECHNE-FORM
        END-IF
    END-PERFORM

    *> Sortieren nach Flaeche (Bubblesort)
    PERFORM VARYING I FROM 1 BY 1 UNTIL I >= ANZAHL
        PERFORM VARYING J FROM 1 BY 1 UNTIL J > ANZAHL - I
            IF F-FLAECHE(J) > F-FLAECHE(J + 1)
                MOVE FORM(J) TO TMP-FORM
                MOVE FORM(J + 1) TO FORM(J)
                MOVE TMP-FORM TO FORM(J + 1)
            END-IF
        END-PERFORM
    END-PERFORM

    PERFORM VARYING I FROM 1 BY 1 UNTIL I > ANZAHL
        MOVE F-FLAECHE(I) TO WS-X
        PERFORM FORMAT-2
        MOVE TXT TO T-FL
        MOVE F-UMFANG(I) TO WS-X
        PERFORM FORMAT-2
        MOVE TXT TO T-UM
        IF F-FLAECHE(I) >= 10.0
            MOVE "gross" TO STATUS-TXT
        ELSE
            MOVE "klein" TO STATUS-TXT
        END-IF
        DISPLAY FUNCTION TRIM(F-ART(I)) ": Flaeche=" FUNCTION TRIM(T-FL)
                " Umfang=" FUNCTION TRIM(T-UM) " " STATUS-TXT " Ecken=" F-ECKEN(I)
    END-PERFORM

    MOVE 48 TO WS-GA
    MOVE 18 TO WS-GB
    PERFORM GGT
    MOVE WS-GA TO ED-INT
    DISPLAY "ggT(48, 18) = " FUNCTION TRIM(ED-INT)

    MOVE SPACES TO PRIM-TXT
    PERFORM VARYING WS-N FROM 2 BY 1 UNTIL WS-N > 30
        PERFORM IST-PRIM
        IF WS-GUELTIG = 1
            MOVE WS-N TO ED-INT
            STRING " " FUNCTION TRIM(ED-INT) DELIMITED BY SIZE
                INTO PRIM-TXT WITH POINTER PRIM-PTR
        END-IF
    END-PERFORM
    DISPLAY "Primzahlen bis 30:" FUNCTION TRIM(PRIM-TXT TRAILING)

    MOVE 2.0 TO WS-X
    PERFORM WURZEL
    MOVE WS-W TO WS-X
    PERFORM FORMAT-8
    DISPLAY "Wurzel(2) = " FUNCTION TRIM(TXT)

    CALL "CBL_AND" USING BYTE-HEX BYTE-MASKE BY VALUE 1   *> 0xFF AND 0xAA
    COMPUTE MASKE = FUNCTION ORD(BYTE-MASKE) - 1
    COMPUTE SKALA = 1000000 / 8
    MOVE MASKE TO ED-INT
    DISPLAY "Maske: " FUNCTION TRIM(ED-INT)
    MOVE SKALA TO ED-INT
    DISPLAY "Skala: " FUNCTION TRIM(ED-INT)
    STOP RUN.

*> Prueft die Masse von Form I; bei Fehler steht der Text in MELDUNG
PRUEFE-FORM.
    MOVE 1 TO WS-GUELTIG
    MOVE F-A(I) TO WS-X
    PERFORM FORMAT-1
    MOVE TXT TO T1
    MOVE F-B(I) TO WS-X
    PERFORM FORMAT-1
    MOVE TXT TO T2
    MOVE F-C(I) TO WS-X
    PERFORM FORMAT-1
    MOVE TXT TO T3
    EVALUATE FUNCTION TRIM(F-ART(I))
        WHEN "Kreis"
            IF F-A(I) <= 0
                MOVE 0 TO WS-GUELTIG
                STRING "Kreis " FUNCTION TRIM(T1) " ungueltig" DELIMITED BY SIZE INTO MELDUNG
            END-IF
        WHEN "Rechteck"
            IF F-A(I) <= 0 OR F-B(I) <= 0
                MOVE 0 TO WS-GUELTIG
                STRING "Rechteck " FUNCTION TRIM(T1) "/" FUNCTION TRIM(T2) " ungueltig"
                    DELIMITED BY SIZE INTO MELDUNG
            END-IF
        WHEN "Dreieck"
            IF F-A(I) + F-B(I) <= F-C(I) OR F-A(I) + F-C(I) <= F-B(I)
               OR F-B(I) + F-C(I) <= F-A(I)
                MOVE 0 TO WS-GUELTIG
                STRING "Dreieck " FUNCTION TRIM(T1) "/" FUNCTION TRIM(T2) "/"
                    FUNCTION TRIM(T3) " ungueltig" DELIMITED BY SIZE INTO MELDUNG
            END-IF
    END-EVALUATE.

*> Berechnet Flaeche, Umfang und Eckenzahl der Form ANZAHL
BERECHNE-FORM.
    EVALUATE FUNCTION TRIM(F-ART(ANZAHL))
        WHEN "Kreis"
            COMPUTE F-FLAECHE(ANZAHL) = PI-WERT * F-A(ANZAHL) * F-A(ANZAHL)
            COMPUTE F-UMFANG(ANZAHL) = 2 * PI-WERT * F-A(ANZAHL)
            MOVE 0 TO F-ECKEN(ANZAHL)
        WHEN "Rechteck"
            COMPUTE F-FLAECHE(ANZAHL) = F-A(ANZAHL) * F-B(ANZAHL)
            COMPUTE F-UMFANG(ANZAHL) = 2 * (F-A(ANZAHL) + F-B(ANZAHL))
            MOVE 4 TO F-ECKEN(ANZAHL)
        WHEN "Dreieck"
            COMPUTE F-UMFANG(ANZAHL) = F-A(ANZAHL) + F-B(ANZAHL) + F-C(ANZAHL)
            COMPUTE WS-S = F-UMFANG(ANZAHL) / 2
            COMPUTE WS-X = WS-S * (WS-S - F-A(ANZAHL)) * (WS-S - F-B(ANZAHL))
                           * (WS-S - F-C(ANZAHL))
            PERFORM WURZEL
            MOVE WS-W TO F-FLAECHE(ANZAHL)
            MOVE 3 TO F-ECKEN(ANZAHL)
    END-EVALUATE.

*> Quadratwurzel nach Newton: neu = (alt + x / alt) / 2
WURZEL.
    MOVE 0 TO WS-W
    IF WS-X > 0
        MOVE WS-X TO WS-ALT
        PERFORM VARYING WS-T FROM 1 BY 1 UNTIL WS-T > MAX-SCHRITTE
            COMPUTE WS-NEU = 0.5 * (WS-ALT + WS-X / WS-ALT)
            MOVE WS-NEU TO WS-W
            IF FUNCTION ABS(WS-NEU - WS-ALT) < EPS
                EXIT PERFORM
            END-IF
            MOVE WS-NEU TO WS-ALT
        END-PERFORM
    END-IF.

*> Groesster gemeinsamer Teiler nach Euklid (WS-GA, WS-GB -> WS-GA)
GGT.
    PERFORM UNTIL WS-GB = 0
        COMPUTE WS-REST = FUNCTION MOD(WS-GA, WS-GB)
        MOVE WS-GB TO WS-GA
        MOVE WS-REST TO WS-GB
    END-PERFORM.

*> Primzahltest durch Probedivision (WS-N -> WS-GUELTIG = 1 bei Primzahl)
IST-PRIM.
    MOVE 1 TO WS-GUELTIG
    IF WS-N < 2
        MOVE 0 TO WS-GUELTIG
    END-IF
    PERFORM VARYING WS-T FROM 2 BY 1 UNTIL WS-T * WS-T > WS-N OR WS-GUELTIG = 0
        IF FUNCTION MOD(WS-N, WS-T) = 0
            MOVE 0 TO WS-GUELTIG
        END-IF
    END-PERFORM.

*> Zahlenformatierung: WS-X -> TXT (gerundet, ohne fuehrende Leerzeichen)
FORMAT-1.
    COMPUTE WS-RUND1 ROUNDED = WS-X
    MOVE WS-RUND1 TO ED-1
    MOVE FUNCTION TRIM(ED-1) TO TXT.
FORMAT-2.
    COMPUTE WS-RUND2 ROUNDED = WS-X
    MOVE WS-RUND2 TO ED-2
    MOVE FUNCTION TRIM(ED-2) TO TXT.
FORMAT-8.
    COMPUTE WS-RUND ROUNDED = WS-X
    MOVE WS-RUND TO ED-8
    MOVE FUNCTION TRIM(ED-8) TO TXT.
