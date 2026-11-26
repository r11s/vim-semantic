/* ------------------------------------------------------------------
 * Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
 * Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
 * CUDA C++.  Bauen: nvcc -std=c++17 -o formen 50_cuda.cu && ./formen
 * ------------------------------------------------------------------ */
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

constexpr double PI_WERT = 3.141592653589793;
constexpr double EPS = 1e-9;
constexpr int MAX_SCHRITTE = 50;

/// Eigene Ausnahme fuer ungueltige Masse.
class FormFehler : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

// Quadratwurzel nach Newton - auf Host und Device nutzbar
__host__ __device__ double wurzel(double v) {
    if (v <= 0) return 0.0;
    double x = v;
    for (int i = 0; i < MAX_SCHRITTE; ++i) {
        double nx = 0.5 * (x + v / x);
        double d = nx > x ? nx - x : x - nx;
        if (d < EPS) return nx;
        x = nx;
    }
    return x;
}

// Dreiecksflaeche nach Heron auf der GPU: ein Thread pro Dreieck
__global__ void heronKernel(const double* a, const double* b, const double* c,
                            double* ergebnis, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        double s = (a[i] + b[i] + c[i]) / 2;
        ergebnis[i] = wurzel(s * (s - a[i]) * (s - b[i]) * (s - c[i]));
    }
}

std::string fmt(double x, int n) {
    char puffer[64];
    std::snprintf(puffer, sizeof puffer, "%.*f", n, x);
    return puffer;
}

class Form {
public:
    virtual ~Form() = default;
    virtual double flaeche() const = 0;
    virtual double umfang() const = 0;
    virtual int ecken() const = 0;
    virtual std::string art() const = 0;
};

class Kreis : public Form {
    double r_;
public:
    explicit Kreis(double r) : r_(r) {}
    double flaeche() const override { return PI_WERT * r_ * r_; }
    double umfang() const override { return 2 * PI_WERT * r_; }
    int ecken() const override { return 0; }
    std::string art() const override { return "Kreis"; }
};

class Rechteck : public Form {
    double a_, b_;
public:
    Rechteck(double a, double b) : a_(a), b_(b) {}
    double flaeche() const override { return a_ * b_; }
    double umfang() const override { return 2 * (a_ + b_); }
    int ecken() const override { return 4; }
    std::string art() const override { return "Rechteck"; }
};

class Dreieck : public Form {
    double a_, b_, c_, flaeche_;
public:
    Dreieck(double a, double b, double c) : a_(a), b_(b), c_(c) {
        if (a + b <= c || a + c <= b || b + c <= a)
            throw FormFehler("Dreieck " + fmt(a, 1) + "/" + fmt(b, 1) + "/" + fmt(c, 1) + " ungueltig");
        double* da; double* db; double* dc; double* de;
        cudaMalloc(&da, sizeof(double)); cudaMalloc(&db, sizeof(double));
        cudaMalloc(&dc, sizeof(double)); cudaMalloc(&de, sizeof(double));
        cudaMemcpy(da, &a, sizeof(double), cudaMemcpyHostToDevice);
        cudaMemcpy(db, &b, sizeof(double), cudaMemcpyHostToDevice);
        cudaMemcpy(dc, &c, sizeof(double), cudaMemcpyHostToDevice);
        heronKernel<<<1, 1>>>(da, db, dc, de, 1);
        cudaMemcpy(&flaeche_, de, sizeof(double), cudaMemcpyDeviceToHost);
        cudaFree(da); cudaFree(db); cudaFree(dc); cudaFree(de);
    }
    double flaeche() const override { return flaeche_; }
    double umfang() const override { return a_ + b_ + c_; }
    int ecken() const override { return 3; }
    std::string art() const override { return "Dreieck"; }
};

int ggt(int a, int b) {
    while (b != 0) { int r = a % b; a = b; b = r; }
    return a;
}

bool istPrim(int n) {
    if (n < 2) return false;
    for (int t = 2; t * t <= n; ++t)
        if (n % t == 0) return false;
    return true;
}

int main() {
    std::printf("Formen-Rechner\n");
    std::vector<std::unique_ptr<Form>> formen;
    formen.push_back(std::make_unique<Kreis>(2.5));
    formen.push_back(std::make_unique<Rechteck>(4.0, 3.0));
    const double dreiecke[][3] = {{3.0, 4.0, 5.0}, {1.0, 2.0, 10.0}};   // TODO: weitere Formen
    for (const auto& d : dreiecke) {
        try {
            formen.push_back(std::make_unique<Dreieck>(d[0], d[1], d[2]));
        } catch (const FormFehler& e) {
            std::printf("Fehler: %s\n", e.what());
        }
    }
    std::sort(formen.begin(), formen.end(),
              [](const auto& x, const auto& y) { return x->flaeche() < y->flaeche(); });
    for (const auto& f : formen) {
        const char* status = f->flaeche() >= 10.0 ? "gross" : "klein";
        std::printf("%s: Flaeche=%s Umfang=%s %s Ecken=%d\n", f->art().c_str(),
                    fmt(f->flaeche(), 2).c_str(), fmt(f->umfang(), 2).c_str(), status, f->ecken());
    }
    std::printf("ggT(48, 18) = %d\n", ggt(48, 18));
    std::printf("Primzahlen bis 30:");
    for (int n = 2; n <= 30; ++n)
        if (istPrim(n)) std::printf(" %d", n);
    std::printf("\n");
    std::printf("Wurzel(2) = %s\n", fmt(wurzel(2.0), 8).c_str());
    std::printf("Maske: %d\n", 0xFF & 0b10101010);
    std::printf("Skala: %d\n", 1'000'000 / 8);
    return 0;
}
