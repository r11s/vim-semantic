#!/usr/bin/env groovy
// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
// Start: groovy 32_groovy.groovy
// ------------------------------------------------------------------
/** Konstanten und Hilfsfunktionen (Skriptmethoden sind in Klassen nicht sichtbar). */
class Rechner {
    static final double PI_WERT = 3.141592653589793d   // Kreiszahl
    static final double EPS = 1e-9d                    // Abbruchschwelle fuer Newton
    static final int MAX_SCHRITTE = 50
    static final int MASKE = 0xFF & 0b10101010         // Hex- und Binaerliteral
    static final int SKALA = 1_000_000.intdiv(8)       // Ganzzahldivision

    static def fmt(double x, int stellen) { String.format(Locale.ROOT, "%.${stellen}f", x) }

    /** Quadratwurzel nach Newton: neu = (alt + x / alt) / 2. */
    static double wurzel(double x) {
        if (x <= 0) return 0.0d
        double alt = x
        for (int i = 0; i < MAX_SCHRITTE; i++) {
            double neu = 0.5d * (alt + x / alt)
            if (Math.abs(neu - alt) < EPS) return neu
            alt = neu
        }
        return alt
    }

    /** Groesster gemeinsamer Teiler nach Euklid. */
    static int ggt(int a, int b) {
        while (b != 0) {
            (a, b) = [b, a % b]
        }
        a
    }

    /** Primzahltest durch Probedivision bis zur Wurzel von n. */
    static boolean istPrim(int n) {
        if (n < 2) return false
        int i = 2
        while (i * i <= n) {
            if (n % i == 0) return false
            i++
        }
        true
    }
}

/** Wird geworfen, wenn Masse keine gueltige Form ergeben. */
class FormFehler extends Exception {
    FormFehler(String nachricht) { super(nachricht) }
}

/** Gemeinsame Basis aller Formen. */
abstract class Form {
    String name() { getClass().simpleName }
    abstract double flaeche()
    abstract double umfang()
}

class Kreis extends Form {
    double r
    Kreis(double r) {
        if (r <= 0) throw new FormFehler("Kreis ${String.format(Locale.ROOT, '%.1f', r)} ungueltig")
        this.r = r
    }
    double flaeche() { Rechner.PI_WERT * r * r }
    double umfang() { 2 * Rechner.PI_WERT * r }
}

class Rechteck extends Form {
    double breite, hoehe
    Rechteck(double breite, double hoehe) {
        if (breite <= 0 || hoehe <= 0) {
            throw new FormFehler(String.format(Locale.ROOT, 'Rechteck %.1f/%.1f ungueltig', breite, hoehe))
        }
        this.breite = breite; this.hoehe = hoehe
    }
    double flaeche() { breite * hoehe }
    double umfang() { 2 * (breite + hoehe) }
}

class Dreieck extends Form {
    double a, b, c
    Dreieck(double a, double b, double c) {
        if (a + b <= c || a + c <= b || b + c <= a) {
            throw new FormFehler(String.format(Locale.ROOT, 'Dreieck %.1f/%.1f/%.1f ungueltig', a, b, c))
        }
        this.a = a; this.b = b; this.c = c
    }
    double umfang() { a + b + c }
    double flaeche() {
        double s = umfang() / 2   // Satz des Heron
        Rechner.wurzel(s * (s - a) * (s - b) * (s - c))
    }
}

int ecken(Form form) {
    switch (form.name()) {
        case 'Dreieck': return 3
        case 'Rechteck': return 4
        case 'Kreis': return 0
        default: return -1
    }
}

println 'Formen-Rechner'
List<Form> formen = [new Kreis(2.5d), new Rechteck(4.0d, 3.0d), new Dreieck(3.0d, 4.0d, 5.0d)]
try {
    formen << new Dreieck(1.0d, 2.0d, 10.0d)   // TODO: weitere Formen
} catch (FormFehler fehler) {
    println "Fehler: ${fehler.message}"
}
formen.sort { x, y -> x.flaeche() <=> y.flaeche() }
formen.each { f ->
    String status = f.flaeche() >= 10.0d ? 'gross' : 'klein'
    println "${f.name()}: Flaeche=${Rechner.fmt(f.flaeche(), 2)} Umfang=${Rechner.fmt(f.umfang(), 2)} ${status} Ecken=${ecken(f)}"
}
println "ggT(48, 18) = ${Rechner.ggt(48, 18)}"
println 'Primzahlen bis 30: ' + (2..30).findAll { Rechner.istPrim(it) }.join(' ')
println "Wurzel(2) = ${Rechner.fmt(Rechner.wurzel(2.0d), 8)}"
println "Maske: ${Rechner.MASKE}"
println "Skala: ${Rechner.SKALA}"
