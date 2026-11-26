#!/usr/bin/perl
# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
# ------------------------------------------------------------------
use strict;
use warnings;

use constant PI           => 3.141592653589793;    # Kreiszahl
use constant EPS          => 1e-9;                 # Abbruchschwelle fuer Newton
use constant MAX_SCHRITTE => 50;
use constant MASKE        => 0xFF & 0b10101010;    # Hex- und Binaerliteral
use constant SKALA        => int(1_000_000 / 8);

=pod

=head1 NAME

Formen - Flaeche und Umfang einfacher Formen, dazu etwas Zahlentheorie

=cut

# Wird geworfen, wenn Masse keine gueltige Form ergeben.
package FormFehler;
sub new { my ($klasse, $text) = @_; return bless { text => $text }, $klasse; }
sub text { return $_[0]{text}; }

# Gemeinsame Basis aller Formen.
package Form;
sub name { my $self = shift; return ref $self; }
sub flaeche { die "nicht implementiert\n"; }
sub umfang  { die "nicht implementiert\n"; }

package Kreis;
our @ISA = ('Form');
sub new {
    my ($klasse, $r) = @_;
    die FormFehler->new(sprintf 'Kreis %.1f ungueltig', $r) if $r <= 0;
    return bless { r => $r }, $klasse;
}
sub flaeche { my $s = shift; return main::PI * $s->{r} ** 2; }
sub umfang  { my $s = shift; return 2 * main::PI * $s->{r}; }

package Rechteck;
our @ISA = ('Form');
sub new {
    my ($klasse, $breite, $hoehe) = @_;
    if ($breite <= 0 || $hoehe <= 0) {
        die FormFehler->new(sprintf 'Rechteck %.1f/%.1f ungueltig', $breite, $hoehe);
    }
    return bless { breite => $breite, hoehe => $hoehe }, $klasse;
}
sub flaeche { my $s = shift; return $s->{breite} * $s->{hoehe}; }
sub umfang  { my $s = shift; return 2 * ($s->{breite} + $s->{hoehe}); }

package Dreieck;
our @ISA = ('Form');
sub new {
    my ($klasse, $a, $b, $c) = @_;
    if ($a + $b <= $c || $a + $c <= $b || $b + $c <= $a) {
        die FormFehler->new(sprintf 'Dreieck %.1f/%.1f/%.1f ungueltig', $a, $b, $c);
    }
    return bless { a => $a, b => $b, c => $c }, $klasse;
}
sub umfang { my $s = shift; return $s->{a} + $s->{b} + $s->{c}; }
sub flaeche {
    my $s = shift;
    my $h = $s->umfang / 2;    # Satz des Heron
    return main::wurzel($h * ($h - $s->{a}) * ($h - $s->{b}) * ($h - $s->{c}));
}

package main;

# Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
sub wurzel {
    my ($x) = @_;
    return 0.0 if $x <= 0;
    my $alt = $x;
    for (1 .. MAX_SCHRITTE) {
        my $neu = 0.5 * ($alt + $x / $alt);
        return $neu if abs($neu - $alt) < EPS;
        $alt = $neu;
    }
    return $alt;
}

# Groesster gemeinsamer Teiler nach Euklid.
sub ggt {
    my ($a, $b) = @_;
    ($a, $b) = ($b, $a % $b) while $b != 0;
    return $a;
}

# Primzahltest durch Probedivision bis zur Wurzel von n.
sub ist_prim {
    my ($n) = @_;
    return 0 if $n < 2;
    for (my $i = 2; $i * $i <= $n; $i++) {
        return 0 if $n % $i == 0;
    }
    return 1;
}

sub ecken {
    my ($form) = @_;
    my %tabelle = (Dreieck => 3, Rechteck => 4, Kreis => 0);
    return exists $tabelle{ $form->name } ? $tabelle{ $form->name } : -1;
}

print "Formen-Rechner\n";
my @formen = (Kreis->new(2.5), Rechteck->new(4.0, 3.0), Dreieck->new(3.0, 4.0, 5.0));
eval {
    push @formen, Dreieck->new(1.0, 2.0, 10.0);    # TODO: weitere Formen
    1;
} or do {
    my $fehler = $@;
    die $fehler unless ref $fehler && $fehler->isa('FormFehler');
    print 'Fehler: ', $fehler->text, "\n";
};
for my $f (sort { $a->flaeche <=> $b->flaeche } @formen) {
    my $status = $f->flaeche >= 10.0 ? 'gross' : 'klein';
    printf "%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n",
        $f->name, $f->flaeche, $f->umfang, $status, ecken($f);
}
print 'ggT(48, 18) = ', ggt(48, 18), "\n";
my @prim = grep { ist_prim($_) } 2 .. 30;
print 'Primzahlen bis 30: ', join(' ', @prim), "\n";
printf "Wurzel(2) = %.8f\n", wurzel(2);
print 'Maske: ', MASKE, "\n";
print 'Skala: ', SKALA, "\n";
