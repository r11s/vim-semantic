#!/usr/bin/env python3
# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
# ------------------------------------------------------------------
"""Berechnet Flaeche und Umfang einfacher Formen und etwas Zahlentheorie."""
from abc import ABC, abstractmethod
from typing import List

PI = 3.141592653589793      # Kreiszahl
EPS = 1e-9                  # Abbruchschwelle fuer das Newton-Verfahren
MAX_SCHRITTE = 50
MASKE = 0xFF & 0b1010_1010  # Hex- und Binaerliteral
SKALA = 1_000_000 // 8      # Ganzzahldivision


class FormFehler(Exception):
    """Wird geworfen, wenn Masse keine gueltige Form ergeben."""


def wurzel(x: float) -> float:
    """Quadratwurzel nach Newton: neu = (alt + x / alt) / 2."""
    if x <= 0:
        return 0.0
    alt = x
    for _ in range(MAX_SCHRITTE):
        neu = 0.5 * (alt + x / alt)
        if abs(neu - alt) < EPS:
            return neu
        alt = neu
    return alt


def ggt(a: int, b: int) -> int:
    """Groesster gemeinsamer Teiler nach Euklid."""
    while b != 0:
        a, b = b, a % b
    return a


def ist_prim(n: int) -> bool:
    """Primzahltest durch Probedivision bis zur Wurzel von n."""
    if n < 2:
        return False
    i = 2
    while i * i <= n:
        if n % i == 0:
            return False
        i += 1
    return True


class Form(ABC):
    """Gemeinsame Basis aller Formen."""

    @abstractmethod
    def flaeche(self) -> float: ...

    @abstractmethod
    def umfang(self) -> float: ...

    def name(self) -> str:
        return type(self).__name__


class Kreis(Form):
    def __init__(self, r: float):
        if r <= 0:
            raise FormFehler(f"Kreis {r:.1f} ungueltig")
        self.r = r

    def flaeche(self) -> float:
        return PI * self.r ** 2

    def umfang(self) -> float:
        return 2 * PI * self.r


class Rechteck(Form):
    def __init__(self, breite: float, hoehe: float):
        if breite <= 0 or hoehe <= 0:
            raise FormFehler(f"Rechteck {breite:.1f}/{hoehe:.1f} ungueltig")
        self.breite, self.hoehe = breite, hoehe

    def flaeche(self) -> float:
        return self.breite * self.hoehe

    def umfang(self) -> float:
        return 2 * (self.breite + self.hoehe)


class Dreieck(Form):
    def __init__(self, a: float, b: float, c: float):
        if a + b <= c or a + c <= b or b + c <= a:
            raise FormFehler(f"Dreieck {a:.1f}/{b:.1f}/{c:.1f} ungueltig")
        self.a, self.b, self.c = a, b, c

    def umfang(self) -> float:
        return self.a + self.b + self.c

    def flaeche(self) -> float:
        s = self.umfang() / 2  # Satz des Heron
        return wurzel(s * (s - self.a) * (s - self.b) * (s - self.c))


def ecken(form: Form) -> int:
    match form.name():
        case "Dreieck":
            return 3
        case "Rechteck":
            return 4
        case "Kreis":
            return 0
        case _:
            return -1


def main() -> None:
    print("Formen-Rechner")
    formen: List[Form] = [Kreis(2.5), Rechteck(4.0, 3.0), Dreieck(3.0, 4.0, 5.0)]
    try:
        formen.append(Dreieck(1.0, 2.0, 10.0))  # TODO: weitere Formen
    except FormFehler as fehler:
        print(f"Fehler: {fehler}")
    formen.sort(key=lambda f: f.flaeche())
    for f in formen:
        status = "gross" if f.flaeche() >= 10.0 else "klein"
        print(f"{f.name()}: Flaeche={f.flaeche():.2f} "
              f"Umfang={f.umfang():.2f} {status} Ecken={ecken(f)}")
    print(f"ggT(48, 18) = {ggt(48, 18)}")
    prim = [str(n) for n in range(2, 31) if ist_prim(n)]
    print("Primzahlen bis 30: " + " ".join(prim))
    print(f"Wurzel(2) = {wurzel(2):.8f}")
    print(f"Maske: {MASKE}")
    print(f"Skala: {SKALA}")


if __name__ == "__main__":
    main()
