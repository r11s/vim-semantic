// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Start: java 04_java.java   (Einzeldatei-Modus ab Java 11)
// ------------------------------------------------------------------
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

class Formen {
    static final double PI = 3.141592653589793; // Kreiszahl
    static final double EPS = 1e-9;             // Abbruchschwelle fuer Newton
    static final int MAX_SCHRITTE = 50;
    static final int MASKE = 0xFF & 0b10101010; // Hex- und Binaerliteral
    static final long SKALA = 1_000_000L / 8;

    /** Quadratwurzel nach Newton: neu = (alt + x / alt) / 2. */
    static double wurzel(double x) {
        if (x <= 0) return 0.0;
        double alt = x;
        for (int i = 0; i < MAX_SCHRITTE; i++) {
            double neu = 0.5 * (alt + x / alt);
            if (Math.abs(neu - alt) < EPS) return neu;
            alt = neu;
        }
        return alt;
    }

    /** Groesster gemeinsamer Teiler nach Euklid. */
    static int ggt(int a, int b) {
        while (b != 0) {
            int rest = a % b;
            a = b;
            b = rest;
        }
        return a;
    }

    /** Primzahltest durch Probedivision bis zur Wurzel von n. */
    static boolean istPrim(int n) {
        if (n < 2) return false;
        for (int i = 2; i * i <= n; i++) {
            if (n % i == 0) return false;
        }
        return true;
    }

    static int ecken(Form form) {
        switch (form.name()) {
            case "Dreieck": return 3;
            case "Rechteck": return 4;
            case "Kreis": return 0;
            default: return -1;
        }
    }

    public static void main(String[] args) {
        System.out.println("Formen-Rechner");
        List<Form> formen = new ArrayList<>();
        try {
            formen.add(new Kreis(2.5));
            formen.add(new Rechteck(4.0, 3.0));
            formen.add(new Dreieck(3.0, 4.0, 5.0));
            formen.add(new Dreieck(1.0, 2.0, 10.0)); // TODO: weitere Formen
        } catch (FormFehler fehler) {
            System.out.println("Fehler: " + fehler.getMessage());
        }
        formen.sort(Comparator.comparingDouble(Form::flaeche));
        for (Form f : formen) {
            String status = f.flaeche() >= 10.0 ? "gross" : "klein";
            System.out.printf("%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d%n",
                    f.name(), f.flaeche(), f.umfang(), status, ecken(f));
        }
        System.out.println("ggT(48, 18) = " + ggt(48, 18));
        StringBuilder prim = new StringBuilder();
        for (int n = 2; n <= 30; n++) {
            if (istPrim(n)) prim.append(prim.length() > 0 ? " " : "").append(n);
        }
        System.out.println("Primzahlen bis 30: " + prim);
        System.out.printf("Wurzel(2) = %.8f%n", wurzel(2));
        System.out.println("Maske: " + MASKE);
        System.out.println("Skala: " + SKALA);
    }
}

/** Interface: gemeinsame Schnittstelle aller Formen. */
interface Form {
    double flaeche();
    double umfang();
    String name();
}

/** Wird geworfen, wenn Masse keine gueltige Form ergeben. */
class FormFehler extends Exception {
    FormFehler(String nachricht) {
        super(nachricht);
    }
}

abstract class Basis implements Form {
    @Override
    public String name() {
        return getClass().getSimpleName();
    }
}

class Kreis extends Basis {
    private final double r;

    Kreis(double r) throws FormFehler {
        if (r <= 0) throw new FormFehler(String.format("Kreis %.1f ungueltig", r));
        this.r = r;
    }

    @Override public double flaeche() { return Formen.PI * r * r; }
    @Override public double umfang() { return 2 * Formen.PI * r; }
}

class Rechteck extends Basis {
    private final double breite, hoehe;

    Rechteck(double breite, double hoehe) throws FormFehler {
        if (breite <= 0 || hoehe <= 0) {
            throw new FormFehler(String.format("Rechteck %.1f/%.1f ungueltig", breite, hoehe));
        }
        this.breite = breite;
        this.hoehe = hoehe;
    }

    @Override public double flaeche() { return breite * hoehe; }
    @Override public double umfang() { return 2 * (breite + hoehe); }
}

class Dreieck extends Basis {
    private final double a, b, c;

    Dreieck(double a, double b, double c) throws FormFehler {
        if (a + b <= c || a + c <= b || b + c <= a) {
            throw new FormFehler(String.format("Dreieck %.1f/%.1f/%.1f ungueltig", a, b, c));
        }
        this.a = a;
        this.b = b;
        this.c = c;
    }

    @Override public double umfang() { return a + b + c; }

    @Override
    public double flaeche() {
        double s = umfang() / 2; // Satz des Heron
        return Formen.wurzel(s * (s - a) * (s - b) * (s - c));
    }
}
