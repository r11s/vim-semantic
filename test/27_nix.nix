# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
# Start: nix-instantiate --eval --strict --raw 27_nix.nix
# Nix ist rein funktional: keine Schleifen, kein Modulo, keine Hex-Literale.
# ------------------------------------------------------------------
let
  pi = 3.141592653589793;        # Kreiszahl
  eps = 1.0e-9;                  # Abbruchschwelle fuer Newton
  maxSchritte = 50;
  maske = builtins.bitAnd 255 170;   # 0xFF & 0b10101010 (nur als Dezimalzahlen)
  skala = 1000000 / 8;               # Ganzzahldivision

  /* Hilfsfunktionen: Nix kennt weder abs noch %, noch printf */
  abs = x: if x < 0 then -x else x;
  rest = a: b: a - (a / b) * b;

  # Zahl mit n Nachkommastellen als Text
  fmt = n: x:
    let
      faktor = builtins.foldl' (a: _: a * 10) 1 (builtins.genList (i: i) n);
      zahl = builtins.floor (x * faktor + 0.5);
      ganz = zahl / faktor;
      nach = builtins.toString (zahl - ganz * faktor);
      fuell = builtins.substring 0 (n - builtins.stringLength nach) "000000000";
    in "${builtins.toString ganz}.${fuell}${nach}";

  # Quadratwurzel nach Newton: neu = (alt + x / alt) / 2
  wurzel = x:
    let
      schritt = i: alt:
        let neu = 0.5 * (alt + x / alt);
        in if i >= maxSchritte then alt
           else if abs (neu - alt) < eps then neu
           else schritt (i + 1) neu;
    in if x <= 0 then 0.0 else schritt 0 x;

  # Groesster gemeinsamer Teiler nach Euklid
  ggt = a: b: if b == 0 then a else ggt b (rest a b);

  # Primzahltest durch Probedivision bis zur Wurzel von n
  istPrim = n:
    n >= 2 && builtins.all (i: rest n i != 0)
      (builtins.filter (i: i * i <= n) (builtins.genList (i: i + 2) n));

  # Formen sind Attributmengen; Fehler werden als { fehler = "..."; } zurueckgegeben
  kreis = r:
    if r <= 0 then { fehler = "Kreis ${fmt 1 r} ungueltig"; }
    else { name = "Kreis"; flaeche = pi * r * r; umfang = 2 * pi * r; };

  rechteck = b: h:
    if b <= 0 || h <= 0 then { fehler = "Rechteck ${fmt 1 b}/${fmt 1 h} ungueltig"; }
    else { name = "Rechteck"; flaeche = b * h; umfang = 2 * (b + h); };

  dreieck = a: b: c:
    if a + b <= c || a + c <= b || b + c <= a
    then { fehler = "Dreieck ${fmt 1 a}/${fmt 1 b}/${fmt 1 c} ungueltig"; }
    else
      let s = (a + b + c) / 2;   # Satz des Heron
      in { name = "Dreieck"; flaeche = wurzel (s * (s - a) * (s - b) * (s - c)); umfang = a + b + c; };

  ecken = f: { Dreieck = 3; Rechteck = 4; Kreis = 0; }.${f.name} or (-1);

  kandidaten = [ (kreis 2.5) (rechteck 4.0 3.0) (dreieck 3.0 4.0 5.0) (dreieck 1.0 2.0 10.0) ];  # TODO: weitere Formen
  fehler = builtins.filter (f: f ? fehler) kandidaten;
  formen = builtins.sort (x: y: x.flaeche < y.flaeche) (builtins.filter (f: !(f ? fehler)) kandidaten);

  zeile = f:
    let status = if f.flaeche >= 10.0 then "gross" else "klein";
    in "${f.name}: Flaeche=${fmt 2 f.flaeche} Umfang=${fmt 2 f.umfang} ${status} Ecken=${builtins.toString (ecken f)}";

  prim = builtins.filter istPrim (builtins.genList (i: i + 2) 29);
in builtins.concatStringsSep "\n" ([ "Formen-Rechner" ]
  ++ map (f: "Fehler: ${f.fehler}") fehler
  ++ map zeile formen
  ++ [
    "ggT(48, 18) = ${builtins.toString (ggt 48 18)}"
    "Primzahlen bis 30: ${builtins.concatStringsSep " " (map builtins.toString prim)}"
    "Wurzel(2) = ${fmt 8 (wurzel 2.0)}"
    "Maske: ${builtins.toString maske}"
    "Skala: ${builtins.toString skala}"
  ]) + "\n"
