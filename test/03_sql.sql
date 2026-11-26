-- ------------------------------------------------------------------
-- Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
-- Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
-- Dialekt: SQLite.   Start: sqlite3 :memory: < 03_sql.sql
-- ------------------------------------------------------------------
.headers off
.mode list

/* Konstanten als Tabelle (SQL kennt keine echten Konstanten) */
CREATE TABLE konstante (
    name TEXT PRIMARY KEY,
    wert REAL NOT NULL
);
INSERT INTO konstante VALUES
    ('PI',           3.141592653589793),  -- Kreiszahl
    ('EPS',          1e-9),               -- Abbruchschwelle fuer Newton
    ('MAX_SCHRITTE', 50);

-- Rohdaten: alle Kandidaten, auch ungueltige
CREATE TABLE kandidat (
    id  INTEGER PRIMARY KEY,
    art TEXT NOT NULL,
    a   REAL,
    b   REAL,
    c   REAL
);
INSERT INTO kandidat (art, a, b, c) VALUES
    ('Kreis',    2.5, NULL, NULL),
    ('Rechteck', 4.0, 3.0,  NULL),
    ('Dreieck',  3.0, 4.0,  5.0),
    ('Dreieck',  1.0, 2.0,  10.0);  -- TODO: weitere Formen

/* Die Tabelle "form" lehnt per CHECK ungueltige Masse ab */
CREATE TABLE form (
    id  INTEGER PRIMARY KEY,
    art TEXT NOT NULL CHECK (art IN ('Kreis', 'Rechteck', 'Dreieck')),
    a   REAL NOT NULL CHECK (a > 0),
    b   REAL,
    c   REAL,
    CHECK (art <> 'Rechteck' OR b > 0),
    CHECK (art <> 'Dreieck' OR (b > 0 AND c > 0
           AND a + b > c AND a + c > b AND b + c > a))
);
INSERT OR IGNORE INTO form SELECT id, art, a, b, c FROM kandidat;

SELECT 'Formen-Rechner';
SELECT 'Fehler: ' || art || ' ' || printf('%.1f', a)
       || COALESCE('/' || printf('%.1f', b), '')
       || COALESCE('/' || printf('%.1f', c), '') || ' ungueltig'
  FROM kandidat
 WHERE id NOT IN (SELECT id FROM form);

-- Quadratwurzel nach Newton als rekursive Abfrage:
-- neu = (alt + x / alt) / 2, Abbruch bei |neu - alt| < EPS
CREATE TABLE wurzel_eingabe (schluessel TEXT PRIMARY KEY, x REAL NOT NULL);
INSERT INTO wurzel_eingabe
SELECT 'd' || id,
       (a + b + c) / 2 * ((a + b + c) / 2 - a) * ((a + b + c) / 2 - b) * ((a + b + c) / 2 - c)
  FROM form WHERE art = 'Dreieck';   -- Satz des Heron
INSERT INTO wurzel_eingabe VALUES ('w2', 2.0);

CREATE VIEW wurzel_ergebnis AS
WITH RECURSIVE newton (schluessel, n, x, alt, neu) AS (
    SELECT schluessel, 0, x, x, 0.5 * (x + x / x) FROM wurzel_eingabe WHERE x > 0
    UNION ALL
    SELECT schluessel, n + 1, x, neu, 0.5 * (neu + x / neu)
      FROM newton
     WHERE abs(neu - alt) >= (SELECT wert FROM konstante WHERE name = 'EPS')
       AND n < (SELECT wert FROM konstante WHERE name = 'MAX_SCHRITTE')
)
SELECT schluessel, neu AS w FROM newton n1
 WHERE n = (SELECT MAX(n) FROM newton n2 WHERE n2.schluessel = n1.schluessel);

CREATE VIEW ergebnis AS
SELECT f.id, f.art,
       CASE f.art
           WHEN 'Kreis'    THEN k.wert * f.a * f.a
           WHEN 'Rechteck' THEN f.a * f.b
           ELSE (SELECT w FROM wurzel_ergebnis WHERE schluessel = 'd' || f.id)
       END AS flaeche,
       CASE f.art
           WHEN 'Kreis'    THEN 2 * k.wert * f.a
           WHEN 'Rechteck' THEN 2 * (f.a + f.b)
           ELSE f.a + f.b + f.c
       END AS umfang,
       CASE f.art WHEN 'Dreieck' THEN 3 WHEN 'Rechteck' THEN 4
                  WHEN 'Kreis' THEN 0 ELSE -1 END AS ecken
  FROM form f, konstante k
 WHERE k.name = 'PI';

SELECT art || ': Flaeche=' || printf('%.2f', flaeche)
           || ' Umfang=' || printf('%.2f', umfang)
           || ' ' || CASE WHEN flaeche >= 10.0 THEN 'gross' ELSE 'klein' END
           || ' Ecken=' || ecken
  FROM ergebnis
 ORDER BY flaeche;

-- ggT nach Euklid: (a, b) -> (b, a mod b), bis b = 0
WITH RECURSIVE g (a, b) AS (
    SELECT 48, 18
    UNION ALL
    SELECT b, a % b FROM g WHERE b <> 0
)
SELECT 'ggT(48, 18) = ' || a FROM g WHERE b = 0;

-- Primzahlen: n ist prim, wenn kein t mit t * t <= n die Zahl teilt
WITH RECURSIVE zahl (n) AS (
    SELECT 2 UNION ALL SELECT n + 1 FROM zahl WHERE n < 30
)
SELECT 'Primzahlen bis 30: ' || group_concat(n, ' ')
  FROM (SELECT z.n FROM zahl z
         WHERE NOT EXISTS (SELECT 1 FROM zahl t WHERE t.n * t.n <= z.n AND z.n % t.n = 0)
         ORDER BY z.n);

SELECT 'Wurzel(2) = ' || printf('%.8f', w) FROM wurzel_ergebnis WHERE schluessel = 'w2';
SELECT 'Maske: ' || (0xFF & 0xAA);          -- SQLite kennt Hex-, aber keine Binaerliterale
SELECT 'Skala: ' || (1000000 / 8);          -- Ganzzahldivision
