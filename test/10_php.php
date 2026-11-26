<?php
// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Start: php 10_php.php
// ------------------------------------------------------------------
declare(strict_types=1);

const PI_WERT = 3.141592653589793; // Kreiszahl
const EPS = 1e-9;                  // Abbruchschwelle fuer Newton
const MAX_SCHRITTE = 50;
const MASKE = 0xFF & 0b10101010;   // Hex- und Binaerliteral
const SKALA = 1_000_000 / 8;

/** Wird geworfen, wenn Masse keine gueltige Form ergeben. */
class FormFehler extends Exception
{
}

/**
 * Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
 *
 * @param float $x Radikand
 * @return float Naeherung der Wurzel
 */
function wurzel(float $x): float
{
    if ($x <= 0) {
        return 0.0;
    }
    $alt = $x;
    for ($i = 0; $i < MAX_SCHRITTE; $i++) {
        $neu = 0.5 * ($alt + $x / $alt);
        if (abs($neu - $alt) < EPS) {
            return $neu;
        }
        $alt = $neu;
    }
    return $alt;
}

/** Groesster gemeinsamer Teiler nach Euklid. */
function ggt(int $a, int $b): int
{
    while ($b !== 0) {
        [$a, $b] = [$b, $a % $b];
    }
    return $a;
}

/** Primzahltest durch Probedivision bis zur Wurzel von n. */
function istPrim(int $n): bool
{
    if ($n < 2) {
        return false;
    }
    for ($i = 2; $i * $i <= $n; $i++) {
        if ($n % $i === 0) {
            return false;
        }
    }
    return true;
}

/** Gemeinsame Schnittstelle aller Formen. */
interface Form
{
    public function flaeche(): float;
    public function umfang(): float;
    public function name(): string;
}

abstract class Basis implements Form
{
    public function name(): string
    {
        return static::class;
    }
}

class Kreis extends Basis
{
    public function __construct(private float $r)
    {
        if ($r <= 0) {
            throw new FormFehler(sprintf('Kreis %.1f ungueltig', $r));
        }
    }

    public function flaeche(): float { return PI_WERT * $this->r ** 2; }
    public function umfang(): float { return 2 * PI_WERT * $this->r; }
}

class Rechteck extends Basis
{
    public function __construct(private float $breite, private float $hoehe)
    {
        if ($breite <= 0 || $hoehe <= 0) {
            throw new FormFehler(sprintf('Rechteck %.1f/%.1f ungueltig', $breite, $hoehe));
        }
    }

    public function flaeche(): float { return $this->breite * $this->hoehe; }
    public function umfang(): float { return 2 * ($this->breite + $this->hoehe); }
}

class Dreieck extends Basis
{
    public function __construct(private float $a, private float $b, private float $c)
    {
        if ($a + $b <= $c || $a + $c <= $b || $b + $c <= $a) {
            throw new FormFehler(sprintf('Dreieck %.1f/%.1f/%.1f ungueltig', $a, $b, $c));
        }
    }

    public function umfang(): float { return $this->a + $this->b + $this->c; }

    public function flaeche(): float
    {
        $s = $this->umfang() / 2; // Satz des Heron
        return wurzel($s * ($s - $this->a) * ($s - $this->b) * ($s - $this->c));
    }
}

function ecken(Form $form): int
{
    return match ($form->name()) {
        'Dreieck' => 3,
        'Rechteck' => 4,
        'Kreis' => 0,
        default => -1,
    };
}

echo "Formen-Rechner\n";
$formen = [new Kreis(2.5), new Rechteck(4.0, 3.0), new Dreieck(3.0, 4.0, 5.0)];
try {
    $formen[] = new Dreieck(1.0, 2.0, 10.0); # TODO: weitere Formen
} catch (FormFehler $fehler) {
    echo 'Fehler: ' . $fehler->getMessage() . "\n";
}
usort($formen, fn (Form $x, Form $y) => $x->flaeche() <=> $y->flaeche());
foreach ($formen as $f) {
    $status = $f->flaeche() >= 10.0 ? 'gross' : 'klein';
    printf("%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n",
        $f->name(), $f->flaeche(), $f->umfang(), $status, ecken($f));
}
echo 'ggT(48, 18) = ' . ggt(48, 18) . "\n";
$prim = [];
for ($n = 2; $n <= 30; $n++) {
    if (istPrim($n)) {
        $prim[] = $n;
    }
}
echo 'Primzahlen bis 30: ' . implode(' ', $prim) . "\n";
printf("Wurzel(2) = %.8f\n", wurzel(2.0));
echo 'Maske: ' . MASKE . "\n";
echo 'Skala: ' . SKALA . "\n";
