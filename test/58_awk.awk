#!/usr/bin/gawk -f
# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
# Starten: gawk -f 58_awk.awk   (liest keine Eingabe, alles im BEGIN-Block)
# ------------------------------------------------------------------
function wurzel(v,    x, nx, i) {
    # Quadratwurzel nach Newton
    if (v <= 0) return 0
    x = v
    for (i = 0; i < MAX_SCHRITTE; i++) {
        nx = 0.5 * (x + v / x)
        if (abs(nx - x) < EPS) return nx
        x = nx
    }
    return x
}

function abs(x) { return x < 0 ? -x : x }

# Prueft die Form n; gibt "" bei Erfolg, sonst die Fehlermeldung zurueck
function pruefe(n,    a, b, c, ok, m) {
    a = masse[n, 1]; b = masse[n, 2]; c = masse[n, 3]
    ok = 1
    if (art[n] == "Kreis") ok = (a > 0)
    else if (art[n] == "Rechteck") ok = (a > 0 && b > 0)
    else if (art[n] == "Dreieck") ok = (a + b > c && a + c > b && b + c > a)
    if (ok) return ""
    m = sprintf("%.1f", a)
    if (art[n] != "Kreis") m = m "/" sprintf("%.1f", b)
    if (art[n] == "Dreieck") m = m "/" sprintf("%.1f", c)
    return art[n] " " m " ungueltig"
}

function flaeche(n,    s) {
    switch (art[n]) {
    case "Kreis":
        return PI * masse[n, 1] ^ 2
    case "Rechteck":
        return masse[n, 1] * masse[n, 2]
    case "Dreieck":
        s = (masse[n, 1] + masse[n, 2] + masse[n, 3]) / 2
        return wurzel(s * (s - masse[n, 1]) * (s - masse[n, 2]) * (s - masse[n, 3]))
    }
}

function umfang(n) {
    if (art[n] == "Kreis") return 2 * PI * masse[n, 1]
    if (art[n] == "Rechteck") return 2 * (masse[n, 1] + masse[n, 2])
    return masse[n, 1] + masse[n, 2] + masse[n, 3]
}

function ecken(n) {
    switch (art[n]) {
    case "Kreis": return 0
    case "Rechteck": return 4
    case "Dreieck": return 3
    default: return -1
    }
}

function ggt(a, b,    r) {
    while (b != 0) { r = a % b; a = b; b = r }
    return a
}

function ist_prim(n,    t) {
    if (n < 2) return 0
    for (t = 2; t * t <= n; t++)
        if (n % t == 0) return 0
    return 1
}

function neue_form(a_art, m1, m2, m3) {
    anzahl++
    art[anzahl] = a_art
    masse[anzahl, 1] = m1; masse[anzahl, 2] = m2; masse[anzahl, 3] = m3
}

BEGIN {
    PI = 3.141592653589793
    EPS = 1e-9
    MAX_SCHRITTE = 50
    print "Formen-Rechner"
    neue_form("Kreis", 2.5)
    neue_form("Rechteck", 4.0, 3.0)
    neue_form("Dreieck", 3.0, 4.0, 5.0)
    neue_form("Dreieck", 1.0, 2.0, 10.0)   # TODO: weitere Formen
    for (i = 1; i <= anzahl; i++) {
        fehler = pruefe(i)
        if (fehler != "") print "Fehler: " fehler
        else werte[++gueltig] = i
    }
    # Sortieren nach Flaeche (Einfuegesortierung)
    for (i = 2; i <= gueltig; i++) {
        k = werte[i]
        for (j = i - 1; j >= 1 && flaeche(werte[j]) > flaeche(k); j--) werte[j + 1] = werte[j]
        werte[j + 1] = k
    }
    for (i = 1; i <= gueltig; i++) {
        n = werte[i]
        status = flaeche(n) >= 10.0 ? "gross" : "klein"
        printf "%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n", art[n], flaeche(n), umfang(n), status, ecken(n)
    }
    printf "ggT(48, 18) = %d\n", ggt(48, 18)
    liste = ""
    for (n = 2; n <= 30; n++) if (ist_prim(n)) liste = liste (liste == "" ? "" : " ") n
    print "Primzahlen bis 30: " liste
    printf "Wurzel(2) = %.8f\n", wurzel(2)
    printf "Maske: %d\n", and(0xFF, 0xAA)
    printf "Skala: %d\n", 1000000 / 8
}
