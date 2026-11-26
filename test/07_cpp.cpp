// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Uebersetzen: g++ -std=c++17 -Wall -o formen 07_cpp.cpp
// ------------------------------------------------------------------
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace formen {

constexpr double PI = 3.141592653589793;   // Kreiszahl
constexpr double EPS = 1e-9;               // Abbruchschwelle fuer Newton
constexpr int MAX_SCHRITTE = 50;
constexpr unsigned MASKE = 0xFF & 0b10101010;
constexpr long SKALA = 1'000'000L / 8;

/// Wird geworfen, wenn Masse keine gueltige Form ergeben.
class FormFehler : public std::runtime_error {
public:
    explicit FormFehler(const std::string& nachricht) : std::runtime_error(nachricht) {}
};

/** Quadratwurzel nach Newton: neu = (alt + x / alt) / 2. */
double wurzel(double x) {
    if (x <= 0) return 0.0;
    double alt = x;
    for (int i = 0; i < MAX_SCHRITTE; ++i) {
        const double neu = 0.5 * (alt + x / alt);
        if (std::fabs(neu - alt) < EPS) return neu;
        alt = neu;
    }
    return alt;
}

/** Groesster gemeinsamer Teiler nach Euklid. */
int ggt(int a, int b) {
    while (b != 0) {
        const int rest = a % b;
        a = b;
        b = rest;
    }
    return a;
}

/** Primzahltest durch Probedivision bis zur Wurzel von n. */
bool ist_prim(int n) {
    if (n < 2) return false;
    for (int i = 2; i * i <= n; ++i) {
        if (n % i == 0) return false;
    }
    return true;
}

std::string format(const char* muster, double a, double b = 0, double c = 0) {
    char puffer[64];
    std::snprintf(puffer, sizeof puffer, muster, a, b, c);
    return puffer;
}

/// Abstrakte Basisklasse aller Formen.
class Form {
public:
    virtual ~Form() = default;
    virtual double flaeche() const = 0;
    virtual double umfang() const = 0;
    virtual std::string name() const = 0;
};

class Kreis : public Form {
    double r_;
public:
    explicit Kreis(double r) : r_(r) {
        if (r <= 0) throw FormFehler(format("Kreis %.1f ungueltig", r));
    }
    double flaeche() const override { return PI * r_ * r_; }
    double umfang() const override { return 2 * PI * r_; }
    std::string name() const override { return "Kreis"; }
};

class Rechteck : public Form {
    double breite_, hoehe_;
public:
    Rechteck(double breite, double hoehe) : breite_(breite), hoehe_(hoehe) {
        if (breite <= 0 || hoehe <= 0) {
            throw FormFehler(format("Rechteck %.1f/%.1f ungueltig", breite, hoehe));
        }
    }
    double flaeche() const override { return breite_ * hoehe_; }
    double umfang() const override { return 2 * (breite_ + hoehe_); }
    std::string name() const override { return "Rechteck"; }
};

class Dreieck : public Form {
    double a_, b_, c_;
public:
    Dreieck(double a, double b, double c) : a_(a), b_(b), c_(c) {
        if (a + b <= c || a + c <= b || b + c <= a) {
            throw FormFehler(format("Dreieck %.1f/%.1f/%.1f ungueltig", a, b, c));
        }
    }
    double umfang() const override { return a_ + b_ + c_; }
    double flaeche() const override {
        const double s = umfang() / 2;  // Satz des Heron
        return wurzel(s * (s - a_) * (s - b_) * (s - c_));
    }
    std::string name() const override { return "Dreieck"; }
};

int ecken(const Form& form) {
    const std::string n = form.name();
    if (n == "Dreieck") return 3;
    if (n == "Rechteck") return 4;
    if (n == "Kreis") return 0;
    return -1;
}

}  // namespace formen

int main() {
    using namespace formen;
    std::cout << "Formen-Rechner\n";
    std::vector<std::unique_ptr<Form>> liste;
    try {
        liste.push_back(std::make_unique<Kreis>(2.5));
        liste.push_back(std::make_unique<Rechteck>(4.0, 3.0));
        liste.push_back(std::make_unique<Dreieck>(3.0, 4.0, 5.0));
        liste.push_back(std::make_unique<Dreieck>(1.0, 2.0, 10.0));  // TODO: weitere Formen
    } catch (const FormFehler& fehler) {
        std::cout << "Fehler: " << fehler.what() << '\n';
    }
    std::sort(liste.begin(), liste.end(),
              [](const auto& x, const auto& y) { return x->flaeche() < y->flaeche(); });
    for (const auto& f : liste) {
        const char* status = f->flaeche() >= 10.0 ? "gross" : "klein";
        char zeile[128];
        std::snprintf(zeile, sizeof zeile, "%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d",
                      f->name().c_str(), f->flaeche(), f->umfang(), status, ecken(*f));
        std::cout << zeile << '\n';
    }
    std::cout << "ggT(48, 18) = " << ggt(48, 18) << '\n';
    std::cout << "Primzahlen bis 30:";
    for (int n = 2; n <= 30; ++n) {
        if (ist_prim(n)) std::cout << ' ' << n;
    }
    std::printf("\nWurzel(2) = %.8f\n", wurzel(2));
    std::cout << "Maske: " << MASKE << '\n';
    std::cout << "Skala: " << SKALA << '\n';
    return 0;
}
