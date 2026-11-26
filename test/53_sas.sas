/* ------------------------------------------------------------------
 * Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
 * Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
 * SAS (Base SAS).  Starten: sas 53_sas.sas   (Ausgabe im Log / stdout)
 * SAS kennt keine Klassen und keine Ausnahmen: Fehler = Statusvariable.
 * ------------------------------------------------------------------ */
%let PI_WERT = 3.141592653589793;
%let EPS = 1e-9;
%let MAX_SCHRITTE = 50;

* Eigene Funktionen (PROC FCMP);
proc fcmp outlib=work.formen.funcs;
    /* Quadratwurzel nach Newton */
    function wurzel(v);
        if v <= 0 then return(0);
        x = v;
        do i = 1 to &MAX_SCHRITTE.;
            nx = 0.5 * (x + v / x);
            if abs(nx - x) < &EPS. then return(nx);
            x = nx;
        end;
        return(x);
    endsub;

    function ggt(a, b);
        do while (b ne 0);
            r = mod(a, b);
            a = b;
            b = r;
        end;
        return(a);
    endsub;

    function istprim(n);
        if n < 2 then return(0);
        t = 2;
        do while (t * t <= n);
            if mod(n, t) = 0 then return(0);
            t = t + 1;
        end;
        return(1);
    endsub;
run;
options cmplib=work.formen;

* Formen als Datensatz: Art und Masse;
data formen;
    length art $8;
    input art $ a b c;
    datalines;
Kreis 2.5 . .
Rechteck 4.0 3.0 .
Dreieck 3.0 4.0 5.0
Dreieck 1.0 2.0 10.0
;                                       * TODO: weitere Formen;
run;

data geprueft;
    set formen;
    length meldung $60 status $5;
    gueltig = 1;
    select (art);
        when ('Kreis')    gueltig = (a > 0);
        when ('Rechteck') gueltig = (a > 0 and b > 0);
        when ('Dreieck')  gueltig = (a + b > c and a + c > b and b + c > a);
        otherwise;
    end;
    if not gueltig then do;
        meldung = catx(' ', art, catx('/', put(a, 4.1), put(b, 4.1), put(c, 4.1)), 'ungueltig');
        put 'Fehler: ' meldung;
        delete;
    end;
    select (art);
        when ('Kreis') do;
            flaeche = &PI_WERT. * a * a;  umfang = 2 * &PI_WERT. * a;  ecken = 0;
        end;
        when ('Rechteck') do;
            flaeche = a * b;  umfang = 2 * (a + b);  ecken = 4;
        end;
        when ('Dreieck') do;
            s = (a + b + c) / 2;
            flaeche = wurzel(s * (s - a) * (s - b) * (s - c));
            umfang = a + b + c;  ecken = 3;
        end;
        otherwise ecken = -1;
    end;
    status = ifc(flaeche >= 10.0, 'gross', 'klein');
run;

proc sort data=geprueft;
    by flaeche;
run;

data _null_;
    if _n_ = 1 then put 'Formen-Rechner';
    set geprueft end=ende;
    length zeile $200;
    zeile = trim(art) || ': Flaeche=' || strip(put(flaeche, 8.2)) || ' Umfang=' || strip(put(umfang, 8.2))
            || ' ' || trim(status) || ' Ecken=' || strip(put(ecken, 2.));
    put zeile;
    if ende then do;
        g = ggt(48, 18);
        put 'ggT(48, 18) = ' g;
        liste = '';
        do n = 2 to 30;
            if istprim(n) then liste = catx(' ', liste, n);
        end;
        put 'Primzahlen bis 30: ' liste;
        w = wurzel(2);
        ws = strip(put(w, 10.8));
        put 'Wurzel(2) = ' ws;
        maske = band(255, 170);            /* 0xFF AND 0xAA; Hex-Literale: 'FF'x */
        put 'Maske: ' maske;
        skala = floor(1000000 / 8);
        put 'Skala: ' skala;
    end;
run;
