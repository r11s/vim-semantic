-- ------------------------------------------------------------------
-- Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
-- Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
-- PL/pgSQL (PostgreSQL 16).  Starten: psql -qAt -f 35_plpgsql.sql
-- ------------------------------------------------------------------
\set QUIET on
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS formen CASCADE;
CREATE SCHEMA formen;
SET search_path = formen;

/* Konstanten als Funktionen (PL/pgSQL kennt keine globalen Konstanten) */
CREATE FUNCTION pi_wert() RETURNS double precision
    LANGUAGE sql IMMUTABLE AS $$ SELECT 3.141592653589793::double precision $$;

-- Eine Form: Art und bis zu drei Masse
CREATE TYPE form AS (art text, a double precision, b double precision, c double precision);

CREATE FUNCTION fmt(x double precision, n int) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT round(x::numeric, n)::text $$;

-- Quadratwurzel nach Newton
CREATE FUNCTION wurzel(v double precision) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    eps CONSTANT double precision := 1e-9;
    max_schritte CONSTANT int := 50;
    x double precision;
    nx double precision;
BEGIN
    IF v <= 0 THEN
        RETURN 0;
    END IF;
    x := v;
    FOR i IN 1..max_schritte LOOP
        nx := 0.5 * (x + v / x);
        IF abs(nx - x) < eps THEN
            RETURN nx;
        END IF;
        x := nx;
    END LOOP;
    RETURN x;
END $$;

-- Wirft eine Ausnahme mit SQLSTATE 'FM001' bei ungueltigen Massen
CREATE FUNCTION pruefe(f form) RETURNS void
    LANGUAGE plpgsql AS $$
DECLARE
    ok boolean := true;
BEGIN
    CASE f.art
        WHEN 'Kreis' THEN ok := f.a > 0;
        WHEN 'Rechteck' THEN ok := f.a > 0 AND f.b > 0;
        WHEN 'Dreieck' THEN ok := f.a + f.b > f.c AND f.a + f.c > f.b AND f.b + f.c > f.a;
        ELSE NULL;
    END CASE;
    IF NOT ok THEN
        RAISE EXCEPTION '% %/%/% ungueltig', f.art, fmt(f.a, 1), fmt(f.b, 1), fmt(f.c, 1)
            USING ERRCODE = 'FM001';
    END IF;
END $$;

CREATE FUNCTION flaeche(f form) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    s double precision;
BEGIN
    IF f.art = 'Kreis' THEN
        RETURN pi_wert() * f.a * f.a;
    ELSIF f.art = 'Rechteck' THEN
        RETURN f.a * f.b;
    END IF;
    s := (f.a + f.b + f.c) / 2;
    RETURN wurzel(s * (s - f.a) * (s - f.b) * (s - f.c));
END $$;

CREATE FUNCTION umfang(f form) RETURNS double precision
    LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE f.art WHEN 'Kreis' THEN 2 * pi_wert() * f.a
                      WHEN 'Rechteck' THEN 2 * (f.a + f.b)
                      ELSE f.a + f.b + f.c END $$;

CREATE FUNCTION ecken(f form) RETURNS int
    LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE f.art WHEN 'Kreis' THEN 0 WHEN 'Rechteck' THEN 4 WHEN 'Dreieck' THEN 3 ELSE -1 END $$;

CREATE FUNCTION ggt(a int, b int) RETURNS int
    LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    r int;
BEGIN
    WHILE b <> 0 LOOP
        r := a % b;
        a := b;
        b := r;
    END LOOP;
    RETURN a;
END $$;

CREATE FUNCTION ist_prim(n int) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    t int := 2;
BEGIN
    IF n < 2 THEN RETURN false; END IF;
    WHILE t * t <= n LOOP
        IF n % t = 0 THEN RETURN false; END IF;
        t := t + 1;
    END LOOP;
    RETURN true;
END $$;

-- Hauptprogramm: liefert die Ausgabezeilen
CREATE FUNCTION haupt() RETURNS SETOF text
    LANGUAGE plpgsql AS $$
DECLARE
    alle form[] := ARRAY[ROW('Kreis', 2.5, 0, 0)::form, ROW('Rechteck', 4.0, 3.0, 0)::form,
                         ROW('Dreieck', 3.0, 4.0, 5.0)::form,
                         ROW('Dreieck', 1.0, 2.0, 10.0)::form];  -- TODO: weitere Formen
    f form;
    gueltig form[] := '{}';
    zeile text;
    maske int := x'FF'::int & b'10101010'::int;
BEGIN
    RETURN NEXT 'Formen-Rechner';
    FOREACH f IN ARRAY alle LOOP
        BEGIN
            PERFORM pruefe(f);
            gueltig := gueltig || f;
        EXCEPTION WHEN SQLSTATE 'FM001' THEN
            RETURN NEXT 'Fehler: ' || SQLERRM;
        END;
    END LOOP;
    FOR f IN SELECT (g).* FROM unnest(gueltig) AS g ORDER BY flaeche(g) LOOP
        RETURN NEXT format('%s: Flaeche=%s Umfang=%s %s Ecken=%s', f.art,
            fmt(flaeche(f), 2), fmt(umfang(f), 2),
            CASE WHEN flaeche(f) >= 10.0 THEN 'gross' ELSE 'klein' END, ecken(f));
    END LOOP;
    RETURN NEXT 'ggT(48, 18) = ' || ggt(48, 18);
    SELECT string_agg(n::text, ' ' ORDER BY n) INTO zeile
      FROM generate_series(2, 30) AS n WHERE ist_prim(n);
    RETURN NEXT 'Primzahlen bis 30: ' || zeile;
    RETURN NEXT 'Wurzel(2) = ' || fmt(wurzel(2), 8);
    RETURN NEXT 'Maske: ' || maske;
    RETURN NEXT 'Skala: ' || 1_000_000 / 8;
END $$;

SELECT * FROM haupt();
DROP SCHEMA formen CASCADE;
