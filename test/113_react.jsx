// Formen-Rechner als React-Komponente. TODO: Eingabe pruefen
import React, { useState, useEffect } from 'react';
import './formen.css';

/* Blockkommentar */
const PI = 3.14159;
const flaeche = (form) => (form.art === 'kreis' ? PI * form.r ** 2 : form.a * form.b);

export default function Formen({ liste = [], ...rest }) {
  const [auswahl, setAuswahl] = useState(null);

  useEffect(() => {
    if (!auswahl) return;
    document.title = `Form: ${auswahl.name} (${flaeche(auswahl).toFixed(2)})`;
  }, [auswahl]);

  return (
    <>
      <h1 className="titel" data-nr={1}>Formen &amp; Flaechen</h1>
      <ul {...rest}>
        {liste.map((f) => (
          <li key={f.name} onClick={() => setAuswahl(f)}>
            {/* Kommentar in JSX */}
            {f.name}: {flaeche(f)}
          </li>
        ))}
      </ul>
      {auswahl && <Form.Detail value={auswahl} aktiv />}
    </>
  );
}

class Fehler extends React.Component {
  static #zaehler = 0;
  get text() { return /^\d+(\.\d+)?$/.test(this.props.wert) ? "Zahl" : 'Text'; }
  async render() { await null; return <p style={{ color: 'red' }}>{this.text}</p>; }
}
