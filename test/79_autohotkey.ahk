#Requires AutoHotkey v2.0
; ------------------------------------------------------------------
; Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
; Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
; AutoHotkey v2.  Starten: AutoHotkey64.exe /ErrorStdOut 79_autohotkey.ahk
; ------------------------------------------------------------------
#SingleInstance Force

/*
  Konstanten als globale Variablen (v2 kennt kein const).
*/
global PI_WERT := 3.141592653589793
global EPS := 1e-9
global MAX_SCHRITTE := 50

; Eigene Ausnahme fuer ungueltige Masse
class FormFehler extends Error {
}

class Form {
    Flaeche() => 0.0
    Umfang() => 0.0
    Ecken() => -1
    Art() => "Form"
}

class Kreis extends Form {
    __New(r) {
        this.r := r
    }
    Flaeche() => PI_WERT * this.r * this.r
    Umfang() => 2 * PI_WERT * this.r
    Ecken() => 0
    Art() => "Kreis"
}

class Rechteck extends Form {
    __New(a, b) {
        this.a := a
        this.b := b
    }
    Flaeche() => this.a * this.b
    Umfang() => 2 * (this.a + this.b)
    Ecken() => 4
    Art() => "Rechteck"
}

class Dreieck extends Form {
    __New(a, b, c) {
        if (a + b <= c || a + c <= b || b + c <= a)
            throw FormFehler("Dreieck " Fmt(a, 1) "/" Fmt(b, 1) "/" Fmt(c, 1) " ungueltig")
        this.a := a, this.b := b, this.c := c
    }
    Flaeche() {
        s := (this.a + this.b + this.c) / 2
        return Wurzel(s * (s - this.a) * (s - this.b) * (s - this.c))
    }
    Umfang() => this.a + this.b + this.c
    Ecken() => 3
    Art() => "Dreieck"
}

Fmt(x, n) {
    return Format("{:." n "f}", x)
}

; Quadratwurzel nach Newton
Wurzel(v) {
    if (v <= 0)
        return 0.0
    x := v
    loop MAX_SCHRITTE {
        nx := 0.5 * (x + v / x)
        if (Abs(nx - x) < EPS)
            return nx
        x := nx
    }
    return x
}

Ggt(a, b) {
    while (b != 0) {
        r := Mod(a, b)
        a := b
        b := r
    }
    return a
}

IstPrim(n) {
    if (n < 2)
        return false
    t := 2
    while (t * t <= n) {
        if (Mod(n, t) = 0)
            return false
        t += 1
    }
    return true
}

Ausgeben(text) {
    FileAppend(text "`n", "*")
}

Ausgeben("Formen-Rechner")
formen := [Kreis(2.5), Rechteck(4.0, 3.0)]
for werte in [[3.0, 4.0, 5.0], [1.0, 2.0, 10.0]] {      ; TODO: weitere Formen
    try {
        formen.Push(Dreieck(werte[1], werte[2], werte[3]))
    } catch FormFehler as e {
        Ausgeben("Fehler: " e.Message)
    }
}
; Sortieren nach Flaeche (Einfuegesortierung)
loop formen.Length - 1 {
    i := A_Index + 1
    f := formen[i]
    j := i - 1
    while (j >= 1 && formen[j].Flaeche() > f.Flaeche()) {
        formen[j + 1] := formen[j]
        j -= 1
    }
    formen[j + 1] := f
}
for f in formen {
    status := f.Flaeche() >= 10.0 ? "gross" : "klein"
    Ausgeben(f.Art() ": Flaeche=" Fmt(f.Flaeche(), 2) " Umfang=" Fmt(f.Umfang(), 2) " " status " Ecken=" f.Ecken())
}
Ausgeben("ggT(48, 18) = " Ggt(48, 18))
liste := ""
loop 29 {
    if IstPrim(A_Index + 1)
        liste .= " " (A_Index + 1)
}
Ausgeben("Primzahlen bis 30:" liste)
Ausgeben("Wurzel(2) = " Fmt(Wurzel(2.0), 8))
Ausgeben("Maske: " (0xFF & 0xAA))        ; kein Binaerliteral in AutoHotkey
Ausgeben("Skala: " (1000000 // 8))
ExitApp
