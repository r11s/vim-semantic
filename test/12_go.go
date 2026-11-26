// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Start: go run 12_go.go
// ------------------------------------------------------------------

// Package main berechnet Flaeche und Umfang einfacher Formen.
package main

import (
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
)

const (
	PI          = 3.141592653589793 // Kreiszahl
	EPS         = 1e-9              // Abbruchschwelle fuer Newton
	MaxSchritte = 50
	Maske       = 0xFF & 0b10101010 // Hex- und Binaerliteral
	Skala       = 1_000_000 / 8
)

// ErrForm kennzeichnet ungueltige Masse.
var ErrForm = errors.New("ungueltige Form")

// Form ist die gemeinsame Schnittstelle aller Formen.
type Form interface {
	Flaeche() float64
	Umfang() float64
	Name() string
}

// Kreis hat einen Radius.
type Kreis struct{ r float64 }

// Rechteck hat Breite und Hoehe.
type Rechteck struct{ breite, hoehe float64 }

// Dreieck hat drei Seiten.
type Dreieck struct{ a, b, c float64 }

func (k Kreis) Flaeche() float64    { return PI * k.r * k.r }
func (k Kreis) Umfang() float64     { return 2 * PI * k.r }
func (k Kreis) Name() string        { return "Kreis" }
func (r Rechteck) Flaeche() float64 { return r.breite * r.hoehe }
func (r Rechteck) Umfang() float64  { return 2 * (r.breite + r.hoehe) }
func (r Rechteck) Name() string     { return "Rechteck" }
func (d Dreieck) Umfang() float64   { return d.a + d.b + d.c }
func (d Dreieck) Name() string      { return "Dreieck" }

// Flaeche nach dem Satz des Heron.
func (d Dreieck) Flaeche() float64 {
	s := d.Umfang() / 2
	return wurzel(s * (s - d.a) * (s - d.b) * (s - d.c))
}

func neuesDreieck(a, b, c float64) (Form, error) {
	if a+b <= c || a+c <= b || b+c <= a {
		return nil, fmt.Errorf("Dreieck %.1f/%.1f/%.1f ungueltig: %w", a, b, c, ErrForm)
	}
	return Dreieck{a, b, c}, nil
}

// wurzel berechnet die Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
func wurzel(x float64) float64 {
	if x <= 0 {
		return 0
	}
	alt := x
	for i := 0; i < MaxSchritte; i++ {
		neu := 0.5 * (alt + x/alt)
		if math.Abs(neu-alt) < EPS {
			return neu
		}
		alt = neu
	}
	return alt
}

// ggt ist der groesste gemeinsame Teiler nach Euklid.
func ggt(a, b int) int {
	for b != 0 {
		a, b = b, a%b
	}
	return a
}

// istPrim testet durch Probedivision bis zur Wurzel von n.
func istPrim(n int) bool {
	if n < 2 {
		return false
	}
	for i := 2; i*i <= n; i++ {
		if n%i == 0 {
			return false
		}
	}
	return true
}

func ecken(f Form) int {
	switch f.(type) {
	case Dreieck:
		return 3
	case Rechteck:
		return 4
	case Kreis:
		return 0
	default:
		return -1
	}
}

func main() {
	fmt.Println("Formen-Rechner")
	formen := []Form{Kreis{2.5}, Rechteck{4.0, 3.0}}
	for _, seiten := range [][3]float64{{3, 4, 5}, {1, 2, 10}} { // TODO: weitere Formen
		d, err := neuesDreieck(seiten[0], seiten[1], seiten[2])
		if err != nil {
			msg := strings.TrimSuffix(err.Error(), ": "+ErrForm.Error())
			fmt.Println("Fehler: " + msg)
			continue
		}
		formen = append(formen, d)
	}
	sort.Slice(formen, func(i, j int) bool { return formen[i].Flaeche() < formen[j].Flaeche() })
	for _, f := range formen {
		status := "klein"
		if f.Flaeche() >= 10.0 {
			status = "gross"
		}
		fmt.Printf("%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n",
			f.Name(), f.Flaeche(), f.Umfang(), status, ecken(f))
	}
	fmt.Printf("ggT(48, 18) = %d\n", ggt(48, 18))
	var prim []string
	for n := 2; n <= 30; n++ {
		if istPrim(n) {
			prim = append(prim, fmt.Sprint(n))
		}
	}
	fmt.Println("Primzahlen bis 30: " + strings.Join(prim, " "))
	fmt.Printf("Wurzel(2) = %.8f\n", wurzel(2))
	fmt.Printf("Maske: %d\n", Maske)
	fmt.Printf("Skala: %d\n", Skala)
}
