-- ------------------------------------------------------------------
-- Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
-- Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
-- Oracle PL/SQL.  Starten: sqlplus benutzer@db @43_plsql.sql
-- ------------------------------------------------------------------
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF

/* Paket mit Konstanten, Ausnahme und Hilfsfunktionen */
CREATE OR REPLACE PACKAGE formen_pkg AS
    c_pi           CONSTANT NUMBER := 3.141592653589793;
    c_eps          CONSTANT NUMBER := 1e-9;
    c_max_schritte CONSTANT PLS_INTEGER := 50;

    /** Eigene Ausnahme fuer ungueltige Masse. */
    form_fehler EXCEPTION;
    PRAGMA EXCEPTION_INIT(form_fehler, -20001);

    FUNCTION fmt(p_x NUMBER, p_n PLS_INTEGER) RETURN VARCHAR2;
    FUNCTION wurzel(p_v NUMBER) RETURN NUMBER;
    FUNCTION ggt(p_a PLS_INTEGER, p_b PLS_INTEGER) RETURN PLS_INTEGER;
    FUNCTION ist_prim(p_n PLS_INTEGER) RETURN BOOLEAN;
END formen_pkg;
/

CREATE OR REPLACE PACKAGE BODY formen_pkg AS
    FUNCTION fmt(p_x NUMBER, p_n PLS_INTEGER) RETURN VARCHAR2 IS
    BEGIN
        RETURN TRIM(TO_CHAR(p_x, 'FM999990.' || RPAD('0', p_n, '0'), 'NLS_NUMERIC_CHARACTERS=''. '''));
    END fmt;

    -- Quadratwurzel nach Newton
    FUNCTION wurzel(p_v NUMBER) RETURN NUMBER IS
        v_x  NUMBER := p_v;
        v_nx NUMBER;
    BEGIN
        IF p_v <= 0 THEN
            RETURN 0;
        END IF;
        FOR i IN 1 .. c_max_schritte LOOP
            v_nx := 0.5 * (v_x + p_v / v_x);
            IF ABS(v_nx - v_x) < c_eps THEN
                RETURN v_nx;
            END IF;
            v_x := v_nx;
        END LOOP;
        RETURN v_x;
    END wurzel;

    FUNCTION ggt(p_a PLS_INTEGER, p_b PLS_INTEGER) RETURN PLS_INTEGER IS
        v_a PLS_INTEGER := p_a;
        v_b PLS_INTEGER := p_b;
        v_r PLS_INTEGER;
    BEGIN
        WHILE v_b <> 0 LOOP
            v_r := MOD(v_a, v_b);
            v_a := v_b;
            v_b := v_r;
        END LOOP;
        RETURN v_a;
    END ggt;

    FUNCTION ist_prim(p_n PLS_INTEGER) RETURN BOOLEAN IS
        v_t PLS_INTEGER := 2;
    BEGIN
        IF p_n < 2 THEN
            RETURN FALSE;
        END IF;
        WHILE v_t * v_t <= p_n LOOP
            IF MOD(p_n, v_t) = 0 THEN
                RETURN FALSE;
            END IF;
            v_t := v_t + 1;
        END LOOP;
        RETURN TRUE;
    END ist_prim;
END formen_pkg;
/

-- Objekttypen: Basistyp "Form" mit Untertypen (Vererbung)
CREATE OR REPLACE TYPE form_t AS OBJECT (
    dummy NUMBER,
    NOT INSTANTIABLE MEMBER FUNCTION flaeche RETURN NUMBER,
    NOT INSTANTIABLE MEMBER FUNCTION umfang RETURN NUMBER,
    NOT INSTANTIABLE MEMBER FUNCTION ecken RETURN PLS_INTEGER,
    NOT INSTANTIABLE MEMBER FUNCTION art RETURN VARCHAR2
) NOT INSTANTIABLE NOT FINAL;
/

CREATE OR REPLACE TYPE kreis_t UNDER form_t (
    r NUMBER,
    OVERRIDING MEMBER FUNCTION flaeche RETURN NUMBER,
    OVERRIDING MEMBER FUNCTION umfang RETURN NUMBER,
    OVERRIDING MEMBER FUNCTION ecken RETURN PLS_INTEGER,
    OVERRIDING MEMBER FUNCTION art RETURN VARCHAR2
);
/
CREATE OR REPLACE TYPE BODY kreis_t AS
    OVERRIDING MEMBER FUNCTION flaeche RETURN NUMBER IS BEGIN RETURN formen_pkg.c_pi * r * r; END;
    OVERRIDING MEMBER FUNCTION umfang RETURN NUMBER IS BEGIN RETURN 2 * formen_pkg.c_pi * r; END;
    OVERRIDING MEMBER FUNCTION ecken RETURN PLS_INTEGER IS BEGIN RETURN 0; END;
    OVERRIDING MEMBER FUNCTION art RETURN VARCHAR2 IS BEGIN RETURN 'Kreis'; END;
END;
/

CREATE OR REPLACE TYPE rechteck_t UNDER form_t (
    a NUMBER, b NUMBER,
    OVERRIDING MEMBER FUNCTION flaeche RETURN NUMBER,
    OVERRIDING MEMBER FUNCTION umfang RETURN NUMBER,
    OVERRIDING MEMBER FUNCTION ecken RETURN PLS_INTEGER,
    OVERRIDING MEMBER FUNCTION art RETURN VARCHAR2
);
/
CREATE OR REPLACE TYPE BODY rechteck_t AS
    OVERRIDING MEMBER FUNCTION flaeche RETURN NUMBER IS BEGIN RETURN a * b; END;
    OVERRIDING MEMBER FUNCTION umfang RETURN NUMBER IS BEGIN RETURN 2 * (a + b); END;
    OVERRIDING MEMBER FUNCTION ecken RETURN PLS_INTEGER IS BEGIN RETURN 4; END;
    OVERRIDING MEMBER FUNCTION art RETURN VARCHAR2 IS BEGIN RETURN 'Rechteck'; END;
END;
/

CREATE OR REPLACE TYPE dreieck_t UNDER form_t (
    a NUMBER, b NUMBER, c NUMBER,
    OVERRIDING MEMBER FUNCTION flaeche RETURN NUMBER,
    OVERRIDING MEMBER FUNCTION umfang RETURN NUMBER,
    OVERRIDING MEMBER FUNCTION ecken RETURN PLS_INTEGER,
    OVERRIDING MEMBER FUNCTION art RETURN VARCHAR2
);
/
CREATE OR REPLACE TYPE BODY dreieck_t AS
    OVERRIDING MEMBER FUNCTION flaeche RETURN NUMBER IS
        s NUMBER := (a + b + c) / 2;
    BEGIN
        RETURN formen_pkg.wurzel(s * (s - a) * (s - b) * (s - c));
    END;
    OVERRIDING MEMBER FUNCTION umfang RETURN NUMBER IS BEGIN RETURN a + b + c; END;
    OVERRIDING MEMBER FUNCTION ecken RETURN PLS_INTEGER IS BEGIN RETURN 3; END;
    OVERRIDING MEMBER FUNCTION art RETURN VARCHAR2 IS BEGIN RETURN 'Dreieck'; END;
END;
/

DECLARE
    TYPE t_formen IS TABLE OF form_t;
    v_formen t_formen := t_formen();
    v_tmp    form_t;
    v_liste  VARCHAR2(200);

    -- Fabrik mit Pruefung: loest bei ungueltigen Massen formen_pkg.form_fehler aus
    FUNCTION neues_dreieck(p_a NUMBER, p_b NUMBER, p_c NUMBER) RETURN form_t IS
    BEGIN
        IF p_a + p_b <= p_c OR p_a + p_c <= p_b OR p_b + p_c <= p_a THEN
            RAISE_APPLICATION_ERROR(-20001, 'Dreieck ' || formen_pkg.fmt(p_a, 1) || '/' ||
                formen_pkg.fmt(p_b, 1) || '/' || formen_pkg.fmt(p_c, 1) || ' ungueltig');
        END IF;
        RETURN dreieck_t(NULL, p_a, p_b, p_c);
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Formen-Rechner');
    v_formen.EXTEND(2);
    v_formen(1) := kreis_t(NULL, 2.5);
    v_formen(2) := rechteck_t(NULL, 4.0, 3.0);
    FOR d IN (SELECT 3.0 a, 4.0 b, 5.0 c FROM dual UNION ALL
              SELECT 1.0, 2.0, 10.0 FROM dual) LOOP      -- TODO: weitere Formen
        BEGIN
            v_formen.EXTEND;
            v_formen(v_formen.LAST) := neues_dreieck(d.a, d.b, d.c);
        EXCEPTION
            WHEN formen_pkg.form_fehler THEN
                v_formen.TRIM;
                DBMS_OUTPUT.PUT_LINE('Fehler: ' || REGEXP_REPLACE(SQLERRM, '^ORA-20001: ', ''));
        END;
    END LOOP;
    -- Sortieren nach Flaeche (Bubblesort)
    FOR i IN 1 .. v_formen.COUNT - 1 LOOP
        FOR j IN 1 .. v_formen.COUNT - i LOOP
            IF v_formen(j).flaeche() > v_formen(j + 1).flaeche() THEN
                v_tmp := v_formen(j);
                v_formen(j) := v_formen(j + 1);
                v_formen(j + 1) := v_tmp;
            END IF;
        END LOOP;
    END LOOP;
    FOR i IN 1 .. v_formen.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_formen(i).art() || ': Flaeche=' || formen_pkg.fmt(v_formen(i).flaeche(), 2) ||
            ' Umfang=' || formen_pkg.fmt(v_formen(i).umfang(), 2) || ' ' ||
            CASE WHEN v_formen(i).flaeche() >= 10.0 THEN 'gross' ELSE 'klein' END ||
            ' Ecken=' || v_formen(i).ecken());
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('ggT(48, 18) = ' || formen_pkg.ggt(48, 18));
    FOR n IN 2 .. 30 LOOP
        IF formen_pkg.ist_prim(n) THEN
            v_liste := v_liste || ' ' || n;
        END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Primzahlen bis 30:' || v_liste);
    DBMS_OUTPUT.PUT_LINE('Wurzel(2) = ' || formen_pkg.fmt(formen_pkg.wurzel(2), 8));
    DBMS_OUTPUT.PUT_LINE('Maske: ' || BITAND(255, 170));      -- kein Hex-/Binaerliteral in PL/SQL
    DBMS_OUTPUT.PUT_LINE('Skala: ' || TRUNC(1000000 / 8));
END;
/
