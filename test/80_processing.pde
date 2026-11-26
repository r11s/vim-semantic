/* ------------------------------------------------------------------
 * Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
 * Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
 * Processing (Java-Dialekt).  Als Sketch "formen" oeffnen und starten.
 * ------------------------------------------------------------------ */
final double PI_WERT = 3.141592653589793;
final double EPS = 1e-9;
final int MAX_SCHRITTE = 50;

/** Eigene Ausnahme fuer ungueltige Masse. */
class FormFehler extends RuntimeException {
  FormFehler(String meldung) { super(meldung); }
}

interface Form {
  double flaeche();
  double umfang();
  int ecken();
  String art();
}

String fmt(double x, int n) {
  return String.format(java.util.Locale.ROOT, "%." + n + "f", x);
}

// Quadratwurzel nach Newton
double wurzel(double v) {
  if (v <= 0) return 0;
  double x = v;
  for (int i = 0; i < MAX_SCHRITTE; i++) {
    double nx = 0.5 * (x + v / x);
    if (Math.abs(nx - x) < EPS) return nx;
    x = nx;
  }
  return x;
}

class Kreis implements Form {
  double r;
  Kreis(double r) { this.r = r; }
  public double flaeche() { return PI_WERT * r * r; }
  public double umfang() { return 2 * PI_WERT * r; }
  public int ecken() { return 0; }
  public String art() { return "Kreis"; }
}

class Rechteck implements Form {
  double a, b;
  Rechteck(double a, double b) { this.a = a; this.b = b; }
  public double flaeche() { return a * b; }
  public double umfang() { return 2 * (a + b); }
  public int ecken() { return 4; }
  public String art() { return "Rechteck"; }
}

class Dreieck implements Form {
  double a, b, c;
  Dreieck(double a, double b, double c) {
    if (a + b <= c || a + c <= b || b + c <= a)
      throw new FormFehler("Dreieck " + fmt(a, 1) + "/" + fmt(b, 1) + "/" + fmt(c, 1) + " ungueltig");
    this.a = a; this.b = b; this.c = c;
  }
  public double flaeche() {
    double s = (a + b + c) / 2;
    return wurzel(s * (s - a) * (s - b) * (s - c));
  }
  public double umfang() { return a + b + c; }
  public int ecken() { return 3; }
  public String art() { return "Dreieck"; }
}

int ggt(int a, int b) {
  while (b != 0) { int r = a % b; a = b; b = r; }
  return a;
}

boolean istPrim(int n) {
  if (n < 2) return false;
  for (int t = 2; t * t <= n; t++) if (n % t == 0) return false;
  return true;
}

void setup() {
  println("Formen-Rechner");
  ArrayList<Form> formen = new ArrayList<Form>();
  formen.add(new Kreis(2.5));
  formen.add(new Rechteck(4.0, 3.0));
  double[][] dreiecke = { {3.0, 4.0, 5.0}, {1.0, 2.0, 10.0} };   // TODO: weitere Formen
  for (double[] d : dreiecke) {
    try {
      formen.add(new Dreieck(d[0], d[1], d[2]));
    } catch (FormFehler e) {
      println("Fehler: " + e.getMessage());
    }
  }
  formen.sort((x, y) -> Double.compare(x.flaeche(), y.flaeche()));
  for (Form f : formen) {
    String status = f.flaeche() >= 10.0 ? "gross" : "klein";
    println(f.art() + ": Flaeche=" + fmt(f.flaeche(), 2) + " Umfang=" + fmt(f.umfang(), 2)
            + " " + status + " Ecken=" + f.ecken());
  }
  println("ggT(48, 18) = " + ggt(48, 18));
  String liste = "";
  for (int n = 2; n <= 30; n++) if (istPrim(n)) liste += " " + n;
  println("Primzahlen bis 30:" + liste);
  println("Wurzel(2) = " + fmt(wurzel(2.0), 8));
  println("Maske: " + (0xFF & 0b10101010));
  println("Skala: " + (1_000_000 / 8));
  exit();
}
