# cython: language_level=3
# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
# Starten: cp 54_cython.pyx formen.pyx && cythonize -i formen.pyx
#          python3 -c "import formen; formen.haupt()"
# (Modulnamen duerfen nicht mit einer Ziffer beginnen.)
# ------------------------------------------------------------------
from libc.math cimport fabs

DEF PI = 3.141592653589793
DEF EPS = 1e-9
DEF MAX_SCHRITTE = 50


class FormFehler(Exception):
    """Eigene Ausnahme fuer ungueltige Masse."""


cdef double wurzel(double v):
    # Quadratwurzel nach Newton
    cdef double x, nx
    cdef int i
    if v <= 0:
        return 0.0
    x = v
    for i in range(MAX_SCHRITTE):
        nx = 0.5 * (x + v / x)
        if fabs(nx - x) < EPS:
            return nx
        x = nx
    return x


cdef class Form:
    """Basisklasse mit typisierten Methoden."""
    cpdef double flaeche(self):
        raise NotImplementedError
    cpdef double umfang(self):
        raise NotImplementedError
    cpdef int ecken(self):
        return -1
    cpdef str art(self):
        return "Form"


cdef class Kreis(Form):
    cdef double r
    def __init__(self, double r):
        if r <= 0:
            raise FormFehler(f"Kreis {r:.1f} ungueltig")
        self.r = r
    cpdef double flaeche(self):
        return PI * self.r * self.r
    cpdef double umfang(self):
        return 2 * PI * self.r
    cpdef int ecken(self):
        return 0
    cpdef str art(self):
        return "Kreis"


cdef class Rechteck(Form):
    cdef double a, b
    def __init__(self, double a, double b):
        if a <= 0 or b <= 0:
            raise FormFehler(f"Rechteck {a:.1f}/{b:.1f} ungueltig")
        self.a = a
        self.b = b
    cpdef double flaeche(self):
        return self.a * self.b
    cpdef double umfang(self):
        return 2 * (self.a + self.b)
    cpdef int ecken(self):
        return 4
    cpdef str art(self):
        return "Rechteck"


cdef class Dreieck(Form):
    cdef double a, b, c
    def __init__(self, double a, double b, double c):
        if a + b <= c or a + c <= b or b + c <= a:
            raise FormFehler(f"Dreieck {a:.1f}/{b:.1f}/{c:.1f} ungueltig")
        self.a, self.b, self.c = a, b, c
    cpdef double flaeche(self):
        cdef double s = (self.a + self.b + self.c) / 2
        return wurzel(s * (s - self.a) * (s - self.b) * (s - self.c))
    cpdef double umfang(self):
        return self.a + self.b + self.c
    cpdef int ecken(self):
        return 3
    cpdef str art(self):
        return "Dreieck"


cdef long ggt(long a, long b):
    cdef long r
    while b != 0:
        r = a % b
        a = b
        b = r
    return a


cdef bint ist_prim(long n):
    cdef long t = 2
    if n < 2:
        return False
    while t * t <= n:
        if n % t == 0:
            return False
        t += 1
    return True


def haupt():
    print("Formen-Rechner")
    formen = []
    for bauen in (lambda: Kreis(2.5), lambda: Rechteck(4.0, 3.0),
                  lambda: Dreieck(3.0, 4.0, 5.0),
                  lambda: Dreieck(1.0, 2.0, 10.0)):  # TODO: weitere Formen
        try:
            formen.append(bauen())
        except FormFehler as e:
            print(f"Fehler: {e}")
    for f in sorted(formen, key=lambda f: f.flaeche()):
        status = "gross" if f.flaeche() >= 10.0 else "klein"
        print(f"{f.art()}: Flaeche={f.flaeche():.2f} Umfang={f.umfang():.2f} {status} Ecken={f.ecken()}")
    print(f"ggT(48, 18) = {ggt(48, 18)}")
    print("Primzahlen bis 30:", " ".join(str(n) for n in range(2, 31) if ist_prim(n)))
    print(f"Wurzel(2) = {wurzel(2.0):.8f}")
    print(f"Maske: {0xFF & 0b10101010}")
    print(f"Skala: {1_000_000 // 8}")


if __name__ == "__main__":
    haupt()
