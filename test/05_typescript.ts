// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// ------------------------------------------------------------------

const PI: number = 3.141592653589793; // Kreiszahl
const EPS: number = 1e-9;             // Abbruchschwelle fuer das Newton-Verfahren
const MAX_SCHRITTE = 50;
const MASKE: number = 0xFF & 0b10101010; // Hex- und Binaerliteral
const SKALA: number = Math.floor(1_000_000 / 8);

type Art = 'Kreis' | 'Rechteck' | 'Dreieck';

/** Wird geworfen, wenn Masse keine gueltige Form ergeben. */
class FormFehler extends Error {
  constructor(nachricht: string) {
    super(nachricht);
    this.name = 'FormFehler';
  }
}

/**
 * Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
 * @param x Radikand
 * @returns Naeherung der Wurzel
 */
function wurzel(x: number): number {
  if (x <= 0) return 0.0;
  let alt = x;
  for (let i = 0; i < MAX_SCHRITTE; i++) {
    const neu = 0.5 * (alt + x / alt);
    if (Math.abs(neu - alt) < EPS) return neu;
    alt = neu;
  }
  return alt;
}

/** Groesster gemeinsamer Teiler nach Euklid. */
function ggt(a: number, b: number): number {
  while (b !== 0) {
    [a, b] = [b, a % b];
  }
  return a;
}

/** Primzahltest durch Probedivision bis zur Wurzel von n. */
function istPrim(n: number): boolean {
  if (n < 2) return false;
  for (let i = 2; i * i <= n; i++) {
    if (n % i === 0) return false;
  }
  return true;
}

/** Gemeinsame Schnittstelle aller Formen. */
interface Form {
  readonly art: Art;
  flaeche(): number;
  umfang(): number;
}

abstract class Basis implements Form {
  abstract readonly art: Art;
  abstract flaeche(): number;
  abstract umfang(): number;
}

class Kreis extends Basis {
  readonly art: Art = 'Kreis';
  constructor(private readonly r: number) {
    super();
    if (r <= 0) throw new FormFehler(`Kreis ${r.toFixed(1)} ungueltig`);
  }
  flaeche(): number { return PI * this.r ** 2; }
  umfang(): number { return 2 * PI * this.r; }
}

class Rechteck extends Basis {
  readonly art: Art = 'Rechteck';
  constructor(private readonly breite: number, private readonly hoehe: number) {
    super();
    if (breite <= 0 || hoehe <= 0) {
      throw new FormFehler(`Rechteck ${breite.toFixed(1)}/${hoehe.toFixed(1)} ungueltig`);
    }
  }
  flaeche(): number { return this.breite * this.hoehe; }
  umfang(): number { return 2 * (this.breite + this.hoehe); }
}

class Dreieck extends Basis {
  readonly art: Art = 'Dreieck';
  constructor(private readonly a: number, private readonly b: number, private readonly c: number) {
    super();
    if (a + b <= c || a + c <= b || b + c <= a) {
      throw new FormFehler(`Dreieck ${a.toFixed(1)}/${b.toFixed(1)}/${c.toFixed(1)} ungueltig`);
    }
  }
  umfang(): number { return this.a + this.b + this.c; }
  flaeche(): number {
    const s = this.umfang() / 2; // Satz des Heron
    return wurzel(s * (s - this.a) * (s - this.b) * (s - this.c));
  }
}

function ecken(art: Art): number {
  switch (art) {
    case 'Dreieck': return 3;
    case 'Rechteck': return 4;
    case 'Kreis': return 0;
    default: return -1;
  }
}

function main(): void {
  console.log('Formen-Rechner');
  const formen: Form[] = [new Kreis(2.5), new Rechteck(4.0, 3.0), new Dreieck(3.0, 4.0, 5.0)];
  try {
    formen.push(new Dreieck(1.0, 2.0, 10.0)); // TODO: weitere Formen
  } catch (fehler) {
    if (!(fehler instanceof FormFehler)) throw fehler;
    console.log(`Fehler: ${fehler.message}`);
  }
  formen.sort((x, y) => x.flaeche() - y.flaeche());
  for (const f of formen) {
    const status = f.flaeche() >= 10.0 ? 'gross' : 'klein';
    console.log(`${f.art}: Flaeche=${f.flaeche().toFixed(2)} ` +
                `Umfang=${f.umfang().toFixed(2)} ${status} Ecken=${ecken(f.art)}`);
  }
  console.log(`ggT(48, 18) = ${ggt(48, 18)}`);
  const prim: number[] = [];
  for (let n = 2; n <= 30; n++) if (istPrim(n)) prim.push(n);
  console.log('Primzahlen bis 30: ' + prim.join(' '));
  console.log(`Wurzel(2) = ${wurzel(2).toFixed(8)}`);
  console.log(`Maske: ${MASKE}`);
  console.log(`Skala: ${SKALA}`);
}

main();
