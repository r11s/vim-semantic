# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
# Mojo.  Starten: mojo 86_mojo.mojo
# ------------------------------------------------------------------
from math import floor

alias PI_WERT: Float64 = 3.141592653589793
alias EPS: Float64 = 1e-9
alias MAX_SCHRITTE = 50

alias KREIS = 0
alias RECHTECK = 1
alias DREIECK = 2


@value
struct FormFehler(Writable):
    """Eigene Fehlermeldung fuer ungueltige Masse."""

    var meldung: String

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.meldung)


trait Messbar:
    """Gemeinsame Schnittstelle aller Formen."""

    fn flaeche(self) -> Float64: ...
    fn umfang(self) -> Float64: ...
    fn ecken(self) -> Int: ...
    fn art(self) -> String: ...


fn fmt(x: Float64, n: Int) -> String:
    var skal = 1
    for _ in range(n):
        skal *= 10
    var wert = Int(x * Float64(skal) + 0.5)
    var rest = String(wert % skal)
    while len(rest) < n:
        rest = "0" + rest
    return String(wert // skal) + "." + rest


# Quadratwurzel nach Newton
fn wurzel(v: Float64) -> Float64:
    if v <= 0:
        return 0.0
    var x = v
    for _ in range(MAX_SCHRITTE):
        var nx = 0.5 * (x + v / x)
        var d = nx - x
        if d < 0:
            d = -d
        if d < EPS:
            return nx
        x = nx
    return x


@value
struct Form(Messbar):
    """Eine Form: Art und bis zu drei Masse."""

    var art_nr: Int
    var a: Float64
    var b: Float64
    var c: Float64

    fn flaeche(self) -> Float64:
        if self.art_nr == KREIS:
            return PI_WERT * self.a * self.a
        elif self.art_nr == RECHTECK:
            return self.a * self.b
        var s = (self.a + self.b + self.c) / 2
        return wurzel(s * (s - self.a) * (s - self.b) * (s - self.c))

    fn umfang(self) -> Float64:
        if self.art_nr == KREIS:
            return 2 * PI_WERT * self.a
        elif self.art_nr == RECHTECK:
            return 2 * (self.a + self.b)
        return self.a + self.b + self.c

    fn ecken(self) -> Int:
        if self.art_nr == KREIS:
            return 0
        elif self.art_nr == RECHTECK:
            return 4
        elif self.art_nr == DREIECK:
            return 3
        return -1

    fn art(self) -> String:
        if self.art_nr == KREIS:
            return "Kreis"
        elif self.art_nr == RECHTECK:
            return "Rechteck"
        return "Dreieck"


fn neue_form(art_nr: Int, a: Float64, b: Float64, c: Float64) raises -> Form:
    """Fabrik mit Pruefung; wirft bei ungueltigen Massen eine Ausnahme."""
    var ok = True
    if art_nr == KREIS:
        ok = a > 0
    elif art_nr == RECHTECK:
        ok = a > 0 and b > 0
    else:
        ok = a + b > c and a + c > b and b + c > a
    if not ok:
        raise Error("Dreieck " + fmt(a, 1) + "/" + fmt(b, 1) + "/" + fmt(c, 1) + " ungueltig")
    return Form(art_nr, a, b, c)


fn ggt(var a: Int, var b: Int) -> Int:
    while b != 0:
        var r = a % b
        a = b
        b = r
    return a


fn ist_prim(n: Int) -> Bool:
    if n < 2:
        return False
    var t = 2
    while t * t <= n:
        if n % t == 0:
            return False
        t += 1
    return True


fn main() raises:
    print("Formen-Rechner")
    var formen = List[Form]()
    formen.append(neue_form(KREIS, 2.5, 0, 0))
    formen.append(neue_form(RECHTECK, 4.0, 3.0, 0))
    var dreiecke = List[List[Float64]]()
    dreiecke.append(List[Float64](3.0, 4.0, 5.0))
    dreiecke.append(List[Float64](1.0, 2.0, 10.0))  # TODO: weitere Formen
    for d in dreiecke:
        try:
            formen.append(neue_form(DREIECK, d[0], d[1], d[2]))
        except e:
            print("Fehler: " + String(e))
    # Sortieren nach Flaeche (Bubblesort)
    for i in range(len(formen) - 1):
        for j in range(len(formen) - 1 - i):
            if formen[j].flaeche() > formen[j + 1].flaeche():
                var tmp = formen[j]
                formen[j] = formen[j + 1]
                formen[j + 1] = tmp
    for f in formen:
        var status = "gross" if f.flaeche() >= 10.0 else "klein"
        print(f.art() + ": Flaeche=" + fmt(f.flaeche(), 2) + " Umfang=" + fmt(f.umfang(), 2)
              + " " + status + " Ecken=" + String(f.ecken()))
    print("ggT(48, 18) = " + String(ggt(48, 18)))
    var liste = String("")
    for n in range(2, 31):
        if ist_prim(n):
            liste += " " + String(n)
    print("Primzahlen bis 30:" + liste)
    print("Wurzel(2) = " + fmt(wurzel(2.0), 8))
    print("Maske: " + String(0xFF & 0b10101010))
    print("Skala: " + String(1_000_000 // 8))
