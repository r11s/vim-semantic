// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
// Starten: scilab-cli -nb -f 78_scilab.sce -quit < /dev/null
// Scilab kennt keine Klassen: Formen sind Strukturen (tlist), Fehler per error().
// ------------------------------------------------------------------
PI_WERT = 3.141592653589793;
EPS = 1e-9;
MAX_SCHRITTE = 50;

/* Zahl mit n Nachkommastellen als Text */
function s = fmt(x, n)
    s = msprintf("%." + string(n) + "f", x);
endfunction

// Quadratwurzel nach Newton
function w = wurzel(v)
    if v <= 0 then
        w = 0;
        return;
    end
    x = v;
    for i = 1:MAX_SCHRITTE
        nx = 0.5 * (x + v / x);
        if abs(nx - x) < EPS then
            x = nx;
            break;
        end
        x = nx;
    end
    w = x;
endfunction

// Neue Form; wirft bei ungueltigen Massen einen Fehler
function f = neue_form(art, masse)
    ok = %t;
    select art
    case "Kreis" then
        ok = masse(1) > 0;
    case "Rechteck" then
        ok = masse(1) > 0 & masse(2) > 0;
    case "Dreieck" then
        a = masse(1); b = masse(2); c = masse(3);
        ok = (a + b > c) & (a + c > b) & (b + c > a);
    end
    if ~ok then
        texte = [];
        for m = masse
            texte = [texte, fmt(m, 1)];
        end
        error(art + " " + strcat(texte, "/") + " ungueltig");
    end
    f = tlist(["form", "art", "masse"], art, masse);
endfunction

function fl = flaeche(f)
    m = f.masse;
    select f.art
    case "Kreis" then
        fl = PI_WERT * m(1) ^ 2;
    case "Rechteck" then
        fl = m(1) * m(2);
    case "Dreieck" then
        s = sum(m) / 2;
        fl = wurzel(s * (s - m(1)) * (s - m(2)) * (s - m(3)));
    end
endfunction

function u = umfang(f)
    m = f.masse;
    select f.art
    case "Kreis" then
        u = 2 * PI_WERT * m(1);
    case "Rechteck" then
        u = 2 * (m(1) + m(2));
    case "Dreieck" then
        u = sum(m);
    end
endfunction

function n = ecken(f)
    select f.art
    case "Kreis" then
        n = 0;
    case "Rechteck" then
        n = 4;
    case "Dreieck" then
        n = 3;
    else
        n = -1;
    end
endfunction

function g = ggt(a, b)
    while b <> 0
        r = modulo(a, b);
        a = b;
        b = r;
    end
    g = a;
endfunction

function r = ist_prim(n)
    r = %t;
    if n < 2 then
        r = %f;
        return;
    end
    t = 2;
    while t * t <= n
        if modulo(n, t) == 0 then
            r = %f;
            return;
        end
        t = t + 1;
    end
endfunction

mprintf("Formen-Rechner\n");
wuensche = list(list("Kreis", 2.5), list("Rechteck", [4.0 3.0]), ..
                list("Dreieck", [3.0 4.0 5.0]), list("Dreieck", [1.0 2.0 10.0])); // TODO: weitere Formen
formen = list();
for k = 1:length(wuensche)
    w = wuensche(k);
    try
        formen($ + 1) = neue_form(w(1), w(2));
    catch
        mprintf("Fehler: %s\n", lasterror());
    end
end
areas = [];
for k = 1:length(formen)
    areas = [areas, flaeche(formen(k))];
end
[sortiert, idx] = gsort(areas, "g", "i");
for k = idx
    f = formen(k);
    if flaeche(f) >= 10.0 then
        status = "gross";
    else
        status = "klein";
    end
    mprintf("%s: Flaeche=%s Umfang=%s %s Ecken=%d\n", f.art, fmt(flaeche(f), 2), fmt(umfang(f), 2), status, ecken(f));
end
mprintf("ggT(48, 18) = %d\n", ggt(48, 18));
liste = "";
for n = 2:30
    if ist_prim(n) then
        liste = liste + " " + string(n);
    end
end
mprintf("Primzahlen bis 30:%s\n", liste);
mprintf("Wurzel(2) = %s\n", fmt(wurzel(2), 8));
mprintf("Maske: %d\n", bitand(255, 170));
mprintf("Skala: %d\n", 1000000 / 8);
