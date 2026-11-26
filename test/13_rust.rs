// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Uebersetzen: rustc -O -o formen 13_rust.rs
// ------------------------------------------------------------------
use std::fmt;

const PI: f64 = 3.141592653589793; // Kreiszahl
const EPS: f64 = 1e-9; // Abbruchschwelle fuer Newton
const MAX_SCHRITTE: u32 = 50;
const MASKE: u32 = 0xFF & 0b1010_1010; // Hex- und Binaerliteral
const SKALA: u64 = 1_000_000 / 8;

/// Fehler, wenn Masse keine gueltige Form ergeben.
#[derive(Debug)]
struct FormFehler(String);

impl fmt::Display for FormFehler {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Gemeinsame Schnittstelle aller Formen (Trait).
trait Form {
    fn flaeche(&self) -> f64;
    fn umfang(&self) -> f64;
    fn name(&self) -> &'static str;
}

struct Kreis {
    r: f64,
}

struct Rechteck {
    breite: f64,
    hoehe: f64,
}

struct Dreieck {
    a: f64,
    b: f64,
    c: f64,
}

impl Kreis {
    fn neu(r: f64) -> Result<Kreis, FormFehler> {
        if r <= 0.0 {
            return Err(FormFehler(format!("Kreis {:.1} ungueltig", r)));
        }
        Ok(Kreis { r })
    }
}

impl Rechteck {
    fn neu(breite: f64, hoehe: f64) -> Result<Rechteck, FormFehler> {
        if breite <= 0.0 || hoehe <= 0.0 {
            return Err(FormFehler(format!("Rechteck {:.1}/{:.1} ungueltig", breite, hoehe)));
        }
        Ok(Rechteck { breite, hoehe })
    }
}

impl Dreieck {
    fn neu(a: f64, b: f64, c: f64) -> Result<Dreieck, FormFehler> {
        if a + b <= c || a + c <= b || b + c <= a {
            return Err(FormFehler(format!("Dreieck {:.1}/{:.1}/{:.1} ungueltig", a, b, c)));
        }
        Ok(Dreieck { a, b, c })
    }
}

impl Form for Kreis {
    fn flaeche(&self) -> f64 { PI * self.r * self.r }
    fn umfang(&self) -> f64 { 2.0 * PI * self.r }
    fn name(&self) -> &'static str { "Kreis" }
}

impl Form for Rechteck {
    fn flaeche(&self) -> f64 { self.breite * self.hoehe }
    fn umfang(&self) -> f64 { 2.0 * (self.breite + self.hoehe) }
    fn name(&self) -> &'static str { "Rechteck" }
}

impl Form for Dreieck {
    fn umfang(&self) -> f64 { self.a + self.b + self.c }
    fn flaeche(&self) -> f64 {
        let s = self.umfang() / 2.0; // Satz des Heron
        wurzel(s * (s - self.a) * (s - self.b) * (s - self.c))
    }
    fn name(&self) -> &'static str { "Dreieck" }
}

/// Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
fn wurzel(x: f64) -> f64 {
    if x <= 0.0 {
        return 0.0;
    }
    let mut alt = x;
    for _ in 0..MAX_SCHRITTE {
        let neu = 0.5 * (alt + x / alt);
        if (neu - alt).abs() < EPS {
            return neu;
        }
        alt = neu;
    }
    alt
}

/// Groesster gemeinsamer Teiler nach Euklid.
fn ggt(mut a: u32, mut b: u32) -> u32 {
    while b != 0 {
        let rest = a % b;
        a = b;
        b = rest;
    }
    a
}

/// Primzahltest durch Probedivision bis zur Wurzel von n.
fn ist_prim(n: u32) -> bool {
    if n < 2 {
        return false;
    }
    let mut i = 2;
    while i * i <= n {
        if n % i == 0 {
            return false;
        }
        i += 1;
    }
    true
}

fn ecken(form: &dyn Form) -> i32 {
    match form.name() {
        "Dreieck" => 3,
        "Rechteck" => 4,
        "Kreis" => 0,
        _ => -1,
    }
}

fn aufbauen() -> Result<Vec<Box<dyn Form>>, FormFehler> {
    let mut formen: Vec<Box<dyn Form>> = Vec::new();
    formen.push(Box::new(Kreis::neu(2.5)?));
    formen.push(Box::new(Rechteck::neu(4.0, 3.0)?));
    formen.push(Box::new(Dreieck::neu(3.0, 4.0, 5.0)?));
    Ok(formen)
}

fn main() {
    println!("Formen-Rechner");
    let mut formen = aufbauen().expect("Aufbau fehlgeschlagen");
    match Dreieck::neu(1.0, 2.0, 10.0) { // TODO: weitere Formen
        Ok(d) => formen.push(Box::new(d)),
        Err(fehler) => println!("Fehler: {}", fehler),
    }
    formen.sort_by(|x, y| x.flaeche().partial_cmp(&y.flaeche()).unwrap());
    for f in &formen {
        let status = if f.flaeche() >= 10.0 { "gross" } else { "klein" };
        println!("{}: Flaeche={:.2} Umfang={:.2} {} Ecken={}",
                 f.name(), f.flaeche(), f.umfang(), status, ecken(f.as_ref()));
    }
    println!("ggT(48, 18) = {}", ggt(48, 18));
    let prim: Vec<String> = (2..=30).filter(|&n| ist_prim(n)).map(|n| n.to_string()).collect();
    println!("Primzahlen bis 30: {}", prim.join(" "));
    println!("Wurzel(2) = {:.8}", wurzel(2.0));
    println!("Maske: {}", MASKE);
    println!("Skala: {}", SKALA);
}
