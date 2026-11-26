/// ------------------------------------------------------------------
/// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
/// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
/// Bauen: gdc -o formen 51_d.d && ./formen
/// ------------------------------------------------------------------
module formen;

import std.stdio : writeln, writefln;
import std.algorithm : sort, map;
import std.array : array, join;
import std.format : format;
import std.conv : to;

enum double PI = 3.141592653589793;
enum double EPS = 1e-9;
enum int MAX_SCHRITTE = 50;

/* Eigene Ausnahme fuer ungueltige Masse */
class FormFehler : Exception
{
    this(string meldung) { super(meldung); }
}

/// Gemeinsame Schnittstelle aller Formen.
interface Form
{
    double flaeche() const;
    double umfang() const;
    string art() const;
    int ecken() const;
}

double wurzel(double v)
{
    if (v <= 0) return 0.0;
    double x = v;
    foreach (i; 0 .. MAX_SCHRITTE)
    {
        immutable nx = 0.5 * (x + v / x);
        if ((nx > x ? nx - x : x - nx) < EPS) return nx;
        x = nx;
    }
    return x;
}

class Kreis : Form
{
    private double r;
    this(double r) { this.r = r; }
    override double flaeche() const { return PI * r * r; }
    override double umfang() const { return 2 * PI * r; }
    override string art() const { return "Kreis"; }
    override int ecken() const { return 0; }
}

class Rechteck : Form
{
    private double a, b;
    this(double a, double b) { this.a = a; this.b = b; }
    override double flaeche() const { return a * b; }
    override double umfang() const { return 2 * (a + b); }
    override string art() const { return "Rechteck"; }
    override int ecken() const { return 4; }
}

class Dreieck : Form
{
    private double a, b, c;
    this(double a, double b, double c)
    {
        if (a + b <= c || a + c <= b || b + c <= a)
            throw new FormFehler(format("Dreieck %.1f/%.1f/%.1f ungueltig", a, b, c));
        this.a = a; this.b = b; this.c = c;
    }
    override double flaeche() const
    {
        immutable s = (a + b + c) / 2;
        return wurzel(s * (s - a) * (s - b) * (s - c));
    }
    override double umfang() const { return a + b + c; }
    override string art() const { return "Dreieck"; }
    override int ecken() const { return 3; }
}

int ggt(int a, int b)
{
    while (b != 0) { immutable r = a % b; a = b; b = r; }
    return a;
}

bool istPrim(int n)
{
    if (n < 2) return false;
    for (int t = 2; t * t <= n; ++t)
        if (n % t == 0) return false;
    return true;
}

void main()
{
    writeln("Formen-Rechner");
    Form[] formen;
    try { formen ~= new Kreis(2.5); } catch (FormFehler e) { writeln("Fehler: ", e.msg); }
    formen ~= new Rechteck(4.0, 3.0);
    foreach (m; [[3.0, 4.0, 5.0], [1.0, 2.0, 10.0]]) // TODO: weitere Formen
    {
        try { formen ~= new Dreieck(m[0], m[1], m[2]); }
        catch (FormFehler e) { writeln("Fehler: ", e.msg); }
    }
    formen.sort!((x, y) => x.flaeche < y.flaeche);
    foreach (f; formen)
    {
        immutable status = f.flaeche >= 10.0 ? "gross" : "klein";
        writefln("%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d",
                 f.art, f.flaeche, f.umfang, status, f.ecken);
    }
    writefln("ggT(48, 18) = %d", ggt(48, 18));
    int[] primzahlen;
    foreach (n; 2 .. 31) if (istPrim(n)) primzahlen ~= n;
    writeln("Primzahlen bis 30: ", primzahlen.map!(to!string).join(" "));
    writefln("Wurzel(2) = %.8f", wurzel(2.0));
    writefln("Maske: %d", 0xFF & 0b10101010);
    writefln("Skala: %d", 1_000_000 / 8);
}
