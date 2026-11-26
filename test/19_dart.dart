// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Start: dart run 19_dart.dart
// ------------------------------------------------------------------

const double kreiszahl = 3.141592653589793; // Kreiszahl
const double eps = 1e-9; // Abbruchschwelle fuer Newton
const int maxSchritte = 50;
const int maske = 0xFF & 0xAA; // Hexliterale; Dart kennt keine Binaerliterale
const int skala = 1000000 ~/ 8; // Ganzzahldivision

/// Wird geworfen, wenn Masse keine gueltige Form ergeben.
class FormFehler implements Exception {
  final String text;
  FormFehler(this.text);

  @override
  String toString() => text;
}

/// Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
double wurzel(double x) {
  if (x <= 0) return 0.0;
  var alt = x;
  for (var i = 0; i < maxSchritte; i++) {
    final neu = 0.5 * (alt + x / alt);
    if ((neu - alt).abs() < eps) return neu;
    alt = neu;
  }
  return alt;
}

/// Groesster gemeinsamer Teiler nach Euklid.
int ggt(int a, int b) {
  while (b != 0) {
    final rest = a % b;
    a = b;
    b = rest;
  }
  return a;
}

/// Primzahltest durch Probedivision bis zur Wurzel von [n].
bool istPrim(int n) {
  if (n < 2) return false;
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return false;
  }
  return true;
}

/// Gemeinsame Basis aller Formen.
abstract class Form {
  String get name => runtimeType.toString();
  double flaeche();
  double umfang();
}

class Kreis extends Form {
  final double r;

  Kreis(this.r) {
    if (r <= 0) throw FormFehler('Kreis ${r.toStringAsFixed(1)} ungueltig');
  }

  @override
  double flaeche() => kreiszahl * r * r;

  @override
  double umfang() => 2 * kreiszahl * r;
}

class Rechteck extends Form {
  final double breite, hoehe;

  Rechteck(this.breite, this.hoehe) {
    if (breite <= 0 || hoehe <= 0) {
      throw FormFehler('Rechteck ${breite.toStringAsFixed(1)}/${hoehe.toStringAsFixed(1)} ungueltig');
    }
  }

  @override
  double flaeche() => breite * hoehe;

  @override
  double umfang() => 2 * (breite + hoehe);
}

class Dreieck extends Form {
  final double a, b, c;

  Dreieck(this.a, this.b, this.c) {
    if (a + b <= c || a + c <= b || b + c <= a) {
      throw FormFehler('Dreieck ${a.toStringAsFixed(1)}/${b.toStringAsFixed(1)}/${c.toStringAsFixed(1)} ungueltig');
    }
  }

  @override
  double umfang() => a + b + c;

  @override
  double flaeche() {
    final s = umfang() / 2; // Satz des Heron
    return wurzel(s * (s - a) * (s - b) * (s - c));
  }
}

int ecken(Form form) => switch (form.name) {
      'Dreieck' => 3,
      'Rechteck' => 4,
      'Kreis' => 0,
      _ => -1,
    };

void main() {
  print('Formen-Rechner');
  final formen = <Form>[Kreis(2.5), Rechteck(4.0, 3.0), Dreieck(3.0, 4.0, 5.0)];
  try {
    formen.add(Dreieck(1.0, 2.0, 10.0)); // TODO: weitere Formen
  } on FormFehler catch (fehler) {
    print('Fehler: $fehler');
  }
  formen.sort((x, y) => x.flaeche().compareTo(y.flaeche()));
  for (final f in formen) {
    final status = f.flaeche() >= 10.0 ? 'gross' : 'klein';
    print('${f.name}: Flaeche=${f.flaeche().toStringAsFixed(2)} '
        'Umfang=${f.umfang().toStringAsFixed(2)} $status Ecken=${ecken(f)}');
  }
  print('ggT(48, 18) = ${ggt(48, 18)}');
  final prim = [for (var n = 2; n <= 30; n++) if (istPrim(n)) n];
  print('Primzahlen bis 30: ${prim.join(' ')}');
  print('Wurzel(2) = ${wurzel(2).toStringAsFixed(8)}');
  print('Maske: $maske');
  print('Skala: $skala');
}
