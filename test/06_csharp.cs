// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// ------------------------------------------------------------------
using System;
using System.Collections.Generic;
using System.Globalization;

namespace FormenRechner
{
    /// <summary>Wird geworfen, wenn Masse keine gueltige Form ergeben.</summary>
    public class FormFehler : Exception
    {
        public FormFehler(string nachricht) : base(nachricht) { }
    }

    /// <summary>Gemeinsame Schnittstelle aller Formen.</summary>
    public interface IForm
    {
        double Flaeche();
        double Umfang();
        string Name { get; }
    }

    public abstract class Basis : IForm
    {
        public abstract double Flaeche();
        public abstract double Umfang();
        public string Name => GetType().Name;
    }

    public class Kreis : Basis
    {
        private readonly double _r;

        public Kreis(double r)
        {
            if (r <= 0) throw new FormFehler($"Kreis {r:F1} ungueltig");
            _r = r;
        }

        public override double Flaeche() => Rechner.PI * _r * _r;
        public override double Umfang() => 2 * Rechner.PI * _r;
    }

    public class Rechteck : Basis
    {
        private readonly double _breite, _hoehe;

        public Rechteck(double breite, double hoehe)
        {
            if (breite <= 0 || hoehe <= 0) throw new FormFehler($"Rechteck {breite:F1}/{hoehe:F1} ungueltig");
            _breite = breite;
            _hoehe = hoehe;
        }

        public override double Flaeche() => _breite * _hoehe;
        public override double Umfang() => 2 * (_breite + _hoehe);
    }

    public class Dreieck : Basis
    {
        private readonly double _a, _b, _c;

        public Dreieck(double a, double b, double c)
        {
            if (a + b <= c || a + c <= b || b + c <= a)
            {
                throw new FormFehler($"Dreieck {a:F1}/{b:F1}/{c:F1} ungueltig");
            }
            (_a, _b, _c) = (a, b, c);
        }

        public override double Umfang() => _a + _b + _c;

        public override double Flaeche()
        {
            double s = Umfang() / 2; // Satz des Heron
            return Rechner.Wurzel(s * (s - _a) * (s - _b) * (s - _c));
        }
    }

    public static class Rechner
    {
        public const double PI = 3.141592653589793;  // Kreiszahl
        public const double EPS = 1e-9;              // Abbruchschwelle fuer Newton
        public const int MaxSchritte = 50;
        public const int Maske = 0xFF & 0b1010_1010; // Hex- und Binaerliteral
        public const long Skala = 1_000_000L / 8;

        /// <summary>Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.</summary>
        public static double Wurzel(double x)
        {
            if (x <= 0) return 0.0;
            double alt = x;
            for (int i = 0; i < MaxSchritte; i++)
            {
                double neu = 0.5 * (alt + x / alt);
                if (Math.Abs(neu - alt) < EPS) return neu;
                alt = neu;
            }
            return alt;
        }

        /// <summary>Groesster gemeinsamer Teiler nach Euklid.</summary>
        public static int Ggt(int a, int b)
        {
            while (b != 0)
            {
                (a, b) = (b, a % b);
            }
            return a;
        }

        /// <summary>Primzahltest durch Probedivision bis zur Wurzel von n.</summary>
        public static bool IstPrim(int n)
        {
            if (n < 2) return false;
            for (int i = 2; i * i <= n; i++)
            {
                if (n % i == 0) return false;
            }
            return true;
        }

        public static int Ecken(IForm form) => form.Name switch
        {
            "Dreieck" => 3,
            "Rechteck" => 4,
            "Kreis" => 0,
            _ => -1,
        };
    }

    public static class Programm
    {
        public static void Main()
        {
            CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
            Console.WriteLine("Formen-Rechner");
            var formen = new List<IForm> { new Kreis(2.5), new Rechteck(4.0, 3.0), new Dreieck(3.0, 4.0, 5.0) };
            try
            {
                formen.Add(new Dreieck(1.0, 2.0, 10.0)); // TODO: weitere Formen
            }
            catch (FormFehler fehler)
            {
                Console.WriteLine($"Fehler: {fehler.Message}");
            }
            formen.Sort((x, y) => x.Flaeche().CompareTo(y.Flaeche()));
            foreach (var f in formen)
            {
                string status = f.Flaeche() >= 10.0 ? "gross" : "klein";
                Console.WriteLine($"{f.Name}: Flaeche={f.Flaeche():F2} Umfang={f.Umfang():F2} {status} Ecken={Rechner.Ecken(f)}");
            }
            Console.WriteLine($"ggT(48, 18) = {Rechner.Ggt(48, 18)}");
            var prim = new List<int>();
            for (int n = 2; n <= 30; n++)
            {
                if (Rechner.IstPrim(n)) prim.Add(n);
            }
            Console.WriteLine("Primzahlen bis 30: " + string.Join(" ", prim));
            Console.WriteLine($"Wurzel(2) = {Rechner.Wurzel(2):F8}");
            Console.WriteLine($"Maske: {Rechner.Maske}");
            Console.WriteLine($"Skala: {Rechner.Skala}");
        }
    }
}
