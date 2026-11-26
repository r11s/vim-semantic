/* ------------------------------------------------------------------
 * Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
 * Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
 * OpenEdge ABL (Progress 4GL).  Starten: _progres -b -p 95_openedge.p
 * ------------------------------------------------------------------ */
&SCOPED-DEFINE PI_WERT 3.141592653589793
&SCOPED-DEFINE EPS 0.000000001
&SCOPED-DEFINE MAX_SCHRITTE 50

DEFINE TEMP-TABLE ttForm NO-UNDO
    FIELD art      AS CHARACTER
    FIELD ma       AS DECIMAL DECIMALS 10
    FIELD mb       AS DECIMAL DECIMALS 10
    FIELD mc       AS DECIMAL DECIMALS 10
    FIELD flaeche  AS DECIMAL DECIMALS 10
    FIELD umfang   AS DECIMAL DECIMALS 10
    FIELD ecken    AS INTEGER
    INDEX idxFlaeche flaeche.

/* Zahl mit n Nachkommastellen als Text */
FUNCTION fmt RETURNS CHARACTER (INPUT x AS DECIMAL, INPUT n AS INTEGER):
    DEFINE VARIABLE fmtText AS CHARACTER NO-UNDO.
    fmtText = TRIM(STRING(ROUND(x, n), ">>>>>>9." + FILL("9", n))).
    RETURN fmtText.
END FUNCTION.

/* Quadratwurzel nach Newton */
FUNCTION wurzel RETURNS DECIMAL (INPUT v AS DECIMAL):
    DEFINE VARIABLE x  AS DECIMAL NO-UNDO.
    DEFINE VARIABLE nx AS DECIMAL NO-UNDO.
    DEFINE VARIABLE i  AS INTEGER NO-UNDO.
    IF v <= 0 THEN RETURN 0.
    x = v.
    DO i = 1 TO {&MAX_SCHRITTE}:
        nx = 0.5 * (x + v / x).
        IF ABSOLUTE(nx - x) < {&EPS} THEN RETURN nx.
        x = nx.
    END.
    RETURN x.
END FUNCTION.

FUNCTION ggt RETURNS INTEGER (INPUT a0 AS INTEGER, INPUT b0 AS INTEGER):
    DEFINE VARIABLE a AS INTEGER NO-UNDO INITIAL 0.
    DEFINE VARIABLE b AS INTEGER NO-UNDO.
    DEFINE VARIABLE r AS INTEGER NO-UNDO.
    ASSIGN a = a0 b = b0.
    DO WHILE b <> 0:
        r = a MODULO b.
        ASSIGN a = b b = r.
    END.
    RETURN a.
END FUNCTION.

FUNCTION istPrim RETURNS LOGICAL (INPUT n AS INTEGER):
    DEFINE VARIABLE t AS INTEGER NO-UNDO INITIAL 2.
    IF n < 2 THEN RETURN FALSE.
    DO WHILE t * t <= n:
        IF n MODULO t = 0 THEN RETURN FALSE.
        t = t + 1.
    END.
    RETURN TRUE.
END FUNCTION.

/* Bitweises Und ueber 8 Bit (ABL hat keinen Operator dafuer) */
FUNCTION bitUnd RETURNS INTEGER (INPUT x AS INTEGER, INPUT y AS INTEGER):
    DEFINE VARIABLE erg AS INTEGER NO-UNDO INITIAL 0.
    DEFINE VARIABLE bit AS INTEGER NO-UNDO INITIAL 1.
    DEFINE VARIABLE k   AS INTEGER NO-UNDO.
    DO k = 1 TO 8:
        IF x MODULO 2 = 1 AND y MODULO 2 = 1 THEN erg = erg + bit.
        ASSIGN x = TRUNCATE(x / 2, 0) y = TRUNCATE(y / 2, 0) bit = bit * 2.
    END.
    RETURN erg.
END FUNCTION.

/* Legt eine Form an; wirft bei ungueltigen Massen einen Fehler (Progress.Lang.AppError) */
PROCEDURE neueForm:
    DEFINE INPUT PARAMETER pArt AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pA   AS DECIMAL NO-UNDO.
    DEFINE INPUT PARAMETER pB   AS DECIMAL NO-UNDO.
    DEFINE INPUT PARAMETER pC   AS DECIMAL NO-UNDO.
    DEFINE VARIABLE s AS DECIMAL NO-UNDO.

    IF pArt = "Dreieck" AND (pA + pB <= pC OR pA + pC <= pB OR pB + pC <= pA) THEN
        UNDO, THROW NEW Progress.Lang.AppError(
            "Dreieck " + fmt(pA, 1) + "/" + fmt(pB, 1) + "/" + fmt(pC, 1) + " ungueltig", 1001).
    CREATE ttForm.
    ASSIGN ttForm.art = pArt ttForm.ma = pA ttForm.mb = pB ttForm.mc = pC.
    CASE pArt:
        WHEN "Kreis" THEN
            ASSIGN ttForm.flaeche = {&PI_WERT} * pA * pA
                   ttForm.umfang  = 2 * {&PI_WERT} * pA
                   ttForm.ecken   = 0.
        WHEN "Rechteck" THEN
            ASSIGN ttForm.flaeche = pA * pB
                   ttForm.umfang  = 2 * (pA + pB)
                   ttForm.ecken   = 4.
        WHEN "Dreieck" THEN DO:
            s = (pA + pB + pC) / 2.
            ASSIGN ttForm.flaeche = wurzel(s * (s - pA) * (s - pB) * (s - pC))
                   ttForm.umfang  = pA + pB + pC
                   ttForm.ecken   = 3.
        END.
        OTHERWISE ttForm.ecken = -1.
    END CASE.
END PROCEDURE.

DEFINE VARIABLE liste AS CHARACTER NO-UNDO.
DEFINE VARIABLE n     AS INTEGER   NO-UNDO.

PUT UNFORMATTED "Formen-Rechner" SKIP.
RUN neueForm("Kreis", 2.5, 0, 0).
RUN neueForm("Rechteck", 4.0, 3.0, 0).
RUN neueForm("Dreieck", 3.0, 4.0, 5.0).
DO ON ERROR UNDO, LEAVE:
    RUN neueForm("Dreieck", 1.0, 2.0, 10.0).   /* TODO: weitere Formen */
    CATCH err AS Progress.Lang.AppError:
        PUT UNFORMATTED "Fehler: " err:ReturnValue SKIP.
        DELETE OBJECT err.
    END CATCH.
END.

FOR EACH ttForm BY ttForm.flaeche:
    PUT UNFORMATTED ttForm.art ": Flaeche=" fmt(ttForm.flaeche, 2) " Umfang=" fmt(ttForm.umfang, 2)
        " " (IF ttForm.flaeche >= 10.0 THEN "gross" ELSE "klein") " Ecken=" ttForm.ecken SKIP.
END.
PUT UNFORMATTED "ggT(48, 18) = " ggt(48, 18) SKIP.
DO n = 2 TO 30:
    IF istPrim(n) THEN liste = liste + " " + STRING(n).
END.
PUT UNFORMATTED "Primzahlen bis 30:" liste SKIP.
PUT UNFORMATTED "Wurzel(2) = " fmt(wurzel(2), 8) SKIP.
PUT UNFORMATTED "Maske: " bitUnd(255, 170) SKIP.      /* 255 = 0xFF, 170 = 0xAA */
PUT UNFORMATTED "Skala: " TRUNCATE(1000000 / 8, 0) SKIP.
