#!/usr/bin/env raku
# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
# Starten: raku 65_raku.raku
# ------------------------------------------------------------------
use v6.d;

constant PI = 3.141592653589793e0;
constant EPS = 1e-9;
constant MAX-SCHRITTE = 50;

#| Eigene Ausnahme fuer ungueltige Masse.
class X::FormFehler is Exception {
    has Str $.meldung;
    method message { $!meldung }
}

#| Gemeinsame Rolle aller Formen.
role Form {
    method flaeche(--> Num) { ... }
    method umfang(--> Num)  { ... }
    method ecken(--> Int)   { ... }
    method art(--> Str)     { ... }
}

sub fmt(Num() $x, Int $n --> Str) { sprintf("%.{$n}f", $x) }

# Quadratwurzel nach Newton
sub wurzel(Num() $v --> Num) {
    return 0e0 if $v <= 0;
    my Num $x = $v;
    for ^MAX-SCHRITTE {
        my Num $nx = 0.5e0 * ($x + $v / $x);
        return $nx if abs($nx - $x) < EPS;
        $x = $nx;
    }
    $x;
}

class Kreis does Form {
    has Num $.r;
    method flaeche(--> Num) { PI * $!r * $!r }
    method umfang(--> Num)  { 2 * PI * $!r }
    method ecken(--> Int)   { 0 }
    method art(--> Str)     { 'Kreis' }
}

class Rechteck does Form {
    has Num ($.a, $.b);
    method flaeche(--> Num) { $!a * $!b }
    method umfang(--> Num)  { 2 * ($!a + $!b) }
    method ecken(--> Int)   { 4 }
    method art(--> Str)     { 'Rechteck' }
}

class Dreieck does Form {
    has Num ($.a, $.b, $.c);
    submethod TWEAK {
        if $!a + $!b <= $!c || $!a + $!c <= $!b || $!b + $!c <= $!a {
            X::FormFehler.new(meldung => "Dreieck {fmt($!a, 1)}/{fmt($!b, 1)}/{fmt($!c, 1)} ungueltig").throw;
        }
    }
    method flaeche(--> Num) {
        my Num $s = ($!a + $!b + $!c) / 2;
        wurzel($s * ($s - $!a) * ($s - $!b) * ($s - $!c));
    }
    method umfang(--> Num) { $!a + $!b + $!c }
    method ecken(--> Int)  { 3 }
    method art(--> Str)    { 'Dreieck' }
}

sub ggt(Int $a is copy, Int $b is copy --> Int) {
    ($a, $b) = ($b, $a % $b) while $b != 0;
    $a;
}

sub ist-prim(Int $n --> Bool) {
    return False if $n < 2;
    so none (2 .. $n.sqrt.floor).map({ $n %% $_ });
}

say 'Formen-Rechner';
my @formen;
@formen.push: Kreis.new(r => 2.5e0);
@formen.push: Rechteck.new(a => 4e0, b => 3e0);
for (3e0, 4e0, 5e0), (1e0, 2e0, 10e0) -> ($a, $b, $c) {   # TODO: weitere Formen
    try {
        @formen.push: Dreieck.new(a => $a, b => $b, c => $c);
        CATCH {
            when X::FormFehler { say "Fehler: {.message}" }
        }
    }
}
for @formen.grep(Form).sort(*.flaeche) -> $f {
    my $status = $f.flaeche >= 10.0 ?? 'gross' !! 'klein';
    say "{$f.art}: Flaeche={fmt($f.flaeche, 2)} Umfang={fmt($f.umfang, 2)} $status Ecken={$f.ecken}";
}
say "ggT(48, 18) = {ggt(48, 18)}";
say "Primzahlen bis 30: {(2..30).grep(&ist-prim).join(' ')}";
say "Wurzel(2) = {fmt(wurzel(2e0), 8)}";
say "Maske: {0xFF +& 0b10101010}";
say "Skala: {1_000_000 div 8}";
