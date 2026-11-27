// Formen-Rechner als React-Komponente mit Typen. TODO: Eingabe pruefen
import React, { useState, type FC } from 'react';

/* Blockkommentar */
type Art = 'kreis' | 'rechteck';

interface Form {
  readonly name: string;
  art: Art;
  r?: number;
  a?: number;
  b?: number;
}

enum Einheit { Cm = 1, M = 100 }

const flaeche = (form: Form): number =>
  form.art === 'kreis' ? Math.PI * (form.r ?? 0) ** 2 : form.a! * form.b!;

const Liste: FC<{ formen: Form[]; einheit?: Einheit }> = ({ formen, einheit = Einheit.Cm }) => {
  const [auswahl, setAuswahl] = useState<Form | null>(null);
  const namen = formen.map((f) => f.name) as ReadonlyArray<string>;

  return (
    <>
      <h1 className="titel" data-nr={1}>Formen &amp; Flaechen</h1>
      <ul>
        {formen.map((f: Form) => (
          <li key={f.name} onClick={() => setAuswahl(f)}>
            {/* Kommentar in TSX */}
            {f.name}: {flaeche(f).toFixed(2)}
          </li>
        ))}
      </ul>
      {auswahl && <Form.Detail value={auswahl} aktiv />}
    </>
  );
};

export class Speicher<T extends Form = Form> implements Iterable<T> {
  private daten: T[] = [];
  public static anzahl: number = 0;
  add(...neu: T[]): this { this.daten.push(...neu); return this; }
  *[Symbol.iterator]() { yield* this.daten; }
}

export default Liste;
