// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Start: swiftc 15_swift.swift -o formen && ./formen
// ------------------------------------------------------------------
import Foundation

// MARK: - Konstanten

let kreiszahl = 3.141592653589793      // Kreiszahl
let eps = 1e-9                         // Abbruchschwelle fuer Newton
let maxSchritte = 50
let maske = 0xFF & 0b1010_1010         // Hex- und Binaerliteral
let skala = 1_000_000 / 8

// MARK: - Fehler und Hilfsfunktionen

/// Wird geworfen, wenn Masse keine gueltige Form ergeben.
struct FormFehler: Error {
    let text: String
}

func zahl(_ x: Double, _ stellen: Int) -> String {
    String(format: "%.\(stellen)f", x)
}

/**
 Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
 - Parameter x: Radikand
 - Returns: Naeherung der Wurzel
 */
func wurzel(_ x: Double) -> Double {
    if x <= 0 { return 0.0 }
    var alt = x
    for _ in 0..<maxSchritte {
        let neu = 0.5 * (alt + x / alt)
        if abs(neu - alt) < eps { return neu }
        alt = neu
    }
    return alt
}

/// Groesster gemeinsamer Teiler nach Euklid.
func ggt(_ a: Int, _ b: Int) -> Int {
    var (a, b) = (a, b)
    while b != 0 {
        (a, b) = (b, a % b)
    }
    return a
}

/// Primzahltest durch Probedivision bis zur Wurzel von n.
func istPrim(_ n: Int) -> Bool {
    if n < 2 { return false }
    var i = 2
    while i * i <= n {
        if n % i == 0 { return false }
        i += 1
    }
    return true
}

// MARK: - Formen

/// Gemeinsame Schnittstelle aller Formen.
protocol Form {
    func flaeche() -> Double
    func umfang() -> Double
}

extension Form {
    var name: String { String(describing: type(of: self)) }
}

struct Kreis: Form {
    let r: Double

    init(_ r: Double) throws {
        guard r > 0 else { throw FormFehler(text: "Kreis \(zahl(r, 1)) ungueltig") }
        self.r = r
    }

    func flaeche() -> Double { kreiszahl * r * r }
    func umfang() -> Double { 2 * kreiszahl * r }
}

struct Rechteck: Form {
    let breite: Double
    let hoehe: Double

    init(_ breite: Double, _ hoehe: Double) throws {
        guard breite > 0, hoehe > 0 else {
            throw FormFehler(text: "Rechteck \(zahl(breite, 1))/\(zahl(hoehe, 1)) ungueltig")
        }
        self.breite = breite
        self.hoehe = hoehe
    }

    func flaeche() -> Double { breite * hoehe }
    func umfang() -> Double { 2 * (breite + hoehe) }
}

struct Dreieck: Form {
    let a: Double, b: Double, c: Double

    init(_ a: Double, _ b: Double, _ c: Double) throws {
        guard a + b > c, a + c > b, b + c > a else {
            throw FormFehler(text: "Dreieck \(zahl(a, 1))/\(zahl(b, 1))/\(zahl(c, 1)) ungueltig")
        }
        self.a = a
        self.b = b
        self.c = c
    }

    func umfang() -> Double { a + b + c }

    func flaeche() -> Double {
        let s = umfang() / 2 // Satz des Heron
        return wurzel(s * (s - a) * (s - b) * (s - c))
    }
}

func ecken(_ form: Form) -> Int {
    switch form.name {
    case "Dreieck": return 3
    case "Rechteck": return 4
    case "Kreis": return 0
    default: return -1
    }
}

// MARK: - Hauptprogramm

print("Formen-Rechner")
var formen: [Form] = []
do {
    try formen.append(Kreis(2.5))
    try formen.append(Rechteck(4.0, 3.0))
    try formen.append(Dreieck(3.0, 4.0, 5.0))
    try formen.append(Dreieck(1.0, 2.0, 10.0)) // TODO: weitere Formen
} catch let fehler as FormFehler {
    print("Fehler: \(fehler.text)")
} catch {
    print("Unerwartet: \(error)")
}
formen.sort { $0.flaeche() < $1.flaeche() }
for f in formen {
    let status = f.flaeche() >= 10.0 ? "gross" : "klein"
    print("\(f.name): Flaeche=\(zahl(f.flaeche(), 2)) Umfang=\(zahl(f.umfang(), 2)) \(status) Ecken=\(ecken(f))")
}
print("ggT(48, 18) = \(ggt(48, 18))")
let prim = (2...30).filter { istPrim($0) }.map { String($0) }.joined(separator: " ")
print("Primzahlen bis 30: \(prim)")
print("Wurzel(2) = \(zahl(wurzel(2), 8))")
print("Maske: \(maske)")
print("Skala: \(skala)")
