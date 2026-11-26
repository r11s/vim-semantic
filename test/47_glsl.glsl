#version 450
#extension GL_ARB_gpu_shader_fp64 : require
/* ------------------------------------------------------------------
 * Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
 * Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
 * GLSL-Compute-Shader.  Pruefen: glslangValidator -S comp -V 47_glsl.glsl
 * Shader koennen nichts ausgeben: das Ergebnis steht im Puffer "Ergebnis"
 * (Host liest es und formatiert wie bei den anderen Sprachen).
 * ------------------------------------------------------------------ */
layout(local_size_x = 1) in;

const double PI_WERT = 3.141592653589793LF;
const double EPS = 1e-9LF;
const int MAX_SCHRITTE = 50;
const int KREIS = 0, RECHTECK = 1, DREIECK = 2;

/// Eine Form: Art und bis zu drei Masse.
struct Form {
    int art;
    double a, b, c;
};

layout(std430, binding = 0) buffer Ergebnis {
    int    fehler[4];     // 1 = ungueltige Masse (statt Ausnahme)
    int    reihenfolge[4];
    double flaeche[4];
    double umfang[4];
    int    ecken[4];
    int    ggt48_18;
    int    primzahlen;    // Bitmaske: Bit n gesetzt, wenn n prim ist
    double wurzel2;
    uint   maske;
    int    skala;
} erg;

// Quadratwurzel nach Newton
double wurzel(double v) {
    if (v <= 0.0LF) return 0.0LF;
    double x = v;
    for (int i = 0; i < MAX_SCHRITTE; i++) {
        double nx = 0.5LF * (x + v / x);
        if (abs(nx - x) < EPS) return nx;
        x = nx;
    }
    return x;
}

bool gueltig(Form f) {
    if (f.art == KREIS) return f.a > 0.0LF;
    if (f.art == RECHTECK) return f.a > 0.0LF && f.b > 0.0LF;
    return f.a + f.b > f.c && f.a + f.c > f.b && f.b + f.c > f.a;
}

double flaecheVon(Form f) {
    switch (f.art) {
    case KREIS:    return PI_WERT * f.a * f.a;
    case RECHTECK: return f.a * f.b;
    default: {
        double s = (f.a + f.b + f.c) / 2.0LF;
        return wurzel(s * (s - f.a) * (s - f.b) * (s - f.c));
    }
    }
}

double umfangVon(Form f) {
    if (f.art == KREIS) return 2.0LF * PI_WERT * f.a;
    if (f.art == RECHTECK) return 2.0LF * (f.a + f.b);
    return f.a + f.b + f.c;
}

int eckenVon(Form f) {
    switch (f.art) {
    case KREIS:    return 0;
    case RECHTECK: return 4;
    case DREIECK:  return 3;
    default:       return -1;
    }
}

int ggt(int a, int b) {
    while (b != 0) { int r = a % b; a = b; b = r; }
    return a;
}

bool istPrim(int n) {
    if (n < 2) return false;
    for (int t = 2; t * t <= n; t++) if (n % t == 0) return false;
    return true;
}

void main() {
    Form formen[4] = Form[4](
        Form(KREIS, 2.5LF, 0.0LF, 0.0LF),
        Form(RECHTECK, 4.0LF, 3.0LF, 0.0LF),
        Form(DREIECK, 3.0LF, 4.0LF, 5.0LF),
        Form(DREIECK, 1.0LF, 2.0LF, 10.0LF));   // TODO: weitere Formen
    for (int i = 0; i < 4; i++) {
        erg.fehler[i] = gueltig(formen[i]) ? 0 : 1;
        erg.flaeche[i] = erg.fehler[i] == 0 ? flaecheVon(formen[i]) : 0.0LF;
        erg.umfang[i] = umfangVon(formen[i]);
        erg.ecken[i] = eckenVon(formen[i]);
        erg.reihenfolge[i] = i;
    }
    // Sortieren nach Flaeche (Bubblesort ueber die Indizes)
    for (int i = 0; i < 3; i++)
        for (int j = 0; j < 3 - i; j++) {
            int p = erg.reihenfolge[j], q = erg.reihenfolge[j + 1];
            if (erg.fehler[p] == 1 || (erg.fehler[q] == 0 && erg.flaeche[p] > erg.flaeche[q])) {
                erg.reihenfolge[j] = q;
                erg.reihenfolge[j + 1] = p;
            }
        }
    erg.ggt48_18 = ggt(48, 18);
    erg.primzahlen = 0;
    for (int n = 2; n <= 30; n++) if (istPrim(n)) erg.primzahlen |= (1 << n);
    erg.wurzel2 = wurzel(2.0LF);
    erg.maske = 0xFFu & 0xAAu;      // kein Binaerliteral in GLSL
    erg.skala = 1000000 / 8;
}
