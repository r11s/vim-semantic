/*
 * ------------------------------------------------------------------
 * Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
 * Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
 * Uebersetzen: gcc -std=c11 -Wall -o formen 09_c.c -lm
 * ------------------------------------------------------------------
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define PI 3.141592653589793   /* Kreiszahl */
#define EPS 1e-9               /* Abbruchschwelle fuer Newton */
#define MAX_SCHRITTE 50
#define MASKE (0xFF & 0xAA)    /* 0xAA == 0b10101010 */
#define SKALA (1000000L / 8)
#define ANZAHL 4

/** Art der Form (C kennt keine Vererbung, daher Enum + Struct). */
typedef enum { KREIS, RECHTECK, DREIECK } Art;

typedef struct {
    Art art;
    double a, b, c;   /* Kreis: a = Radius; Rechteck: a, b; Dreieck: a, b, c */
} Form;

/* Quadratwurzel nach Newton: neu = (alt + x / alt) / 2 */
static double wurzel(double x)
{
    if (x <= 0) return 0.0;
    double alt = x;
    for (int i = 0; i < MAX_SCHRITTE; i++) {
        double neu = 0.5 * (alt + x / alt);
        if (fabs(neu - alt) < EPS) return neu;
        alt = neu;
    }
    return alt;
}

/* Groesster gemeinsamer Teiler nach Euklid */
static int ggt(int a, int b)
{
    while (b != 0) {
        int rest = a % b;
        a = b;
        b = rest;
    }
    return a;
}

/* Primzahltest durch Probedivision bis zur Wurzel von n */
static int ist_prim(int n)
{
    if (n < 2) return 0;
    for (int i = 2; i * i <= n; i++) {
        if (n % i == 0) return 0;
    }
    return 1;
}

static const char *name(const Form *f)
{
    switch (f->art) {
        case KREIS:    return "Kreis";
        case RECHTECK: return "Rechteck";
        case DREIECK:  return "Dreieck";
        default:       return "?";
    }
}

static double umfang(const Form *f)
{
    switch (f->art) {
        case KREIS:    return 2 * PI * f->a;
        case RECHTECK: return 2 * (f->a + f->b);
        default:       return f->a + f->b + f->c;
    }
}

static double flaeche(const Form *f)
{
    switch (f->art) {
        case KREIS:    return PI * f->a * f->a;
        case RECHTECK: return f->a * f->b;
        default: {
            double s = umfang(f) / 2;   /* Satz des Heron */
            return wurzel(s * (s - f->a) * (s - f->b) * (s - f->c));
        }
    }
}

static int ecken(const Form *f)
{
    switch (f->art) {
        case DREIECK:  return 3;
        case RECHTECK: return 4;
        case KREIS:    return 0;
        default:       return -1;
    }
}

/* Prueft die Masse; gibt 0 bei Erfolg zurueck, sonst -1 und eine Meldung */
static int pruefe(const Form *f, char *meldung, size_t groesse)
{
    int ok = 1;
    switch (f->art) {
        case KREIS:
            ok = f->a > 0;
            if (!ok) snprintf(meldung, groesse, "Kreis %.1f ungueltig", f->a);
            break;
        case RECHTECK:
            ok = f->a > 0 && f->b > 0;
            if (!ok) snprintf(meldung, groesse, "Rechteck %.1f/%.1f ungueltig", f->a, f->b);
            break;
        case DREIECK:
            ok = f->a + f->b > f->c && f->a + f->c > f->b && f->b + f->c > f->a;
            if (!ok) {
                snprintf(meldung, groesse, "Dreieck %.1f/%.1f/%.1f ungueltig", f->a, f->b, f->c);
            }
            break;
    }
    return ok ? 0 : -1;
}

static int vergleiche(const void *x, const void *y)
{
    double fx = flaeche(x), fy = flaeche(y);
    return (fx > fy) - (fx < fy);
}

int main(void)
{
    puts("Formen-Rechner");
    const Form kandidaten[ANZAHL] = {
        { KREIS, 2.5, 0, 0 }, { RECHTECK, 4.0, 3.0, 0 },
        { DREIECK, 3.0, 4.0, 5.0 }, { DREIECK, 1.0, 2.0, 10.0 }   /* TODO: weitere Formen */
    };
    Form formen[ANZAHL];
    int anzahl = 0;
    char meldung[64];

    for (int i = 0; i < ANZAHL; i++) {
        if (pruefe(&kandidaten[i], meldung, sizeof meldung) != 0) {
            printf("Fehler: %s\n", meldung);
            continue;
        }
        formen[anzahl++] = kandidaten[i];
    }
    qsort(formen, anzahl, sizeof(Form), vergleiche);
    for (int i = 0; i < anzahl; i++) {
        const char *status = flaeche(&formen[i]) >= 10.0 ? "gross" : "klein";
        printf("%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n", name(&formen[i]),
               flaeche(&formen[i]), umfang(&formen[i]), status, ecken(&formen[i]));
    }
    printf("ggT(48, 18) = %d\n", ggt(48, 18));
    printf("Primzahlen bis 30:");
    for (int n = 2; n <= 30; n++) {
        if (ist_prim(n)) printf(" %d", n);
    }
    printf("\nWurzel(2) = %.8f\n", wurzel(2));
    printf("Maske: %d\n", MASKE);
    printf("Skala: %ld\n", (long) SKALA);
    return EXIT_SUCCESS;
}
