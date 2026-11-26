// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
// Simulation: verilator --binary --timing --top-module formen 66_systemverilog.sv && ./obj_dir/Vformen
// (SystemVerilog-Klassen; Fehler werden ueber ein Flag gemeldet.)
// ------------------------------------------------------------------
`timescale 1ns/1ps

/* Gemeinsame Basisklasse ("Interface") aller Formen */
class Form;
  virtual function real flaeche(); return 0.0; endfunction
  virtual function real umfang(); return 0.0; endfunction
  virtual function int ecken(); return -1; endfunction
  virtual function string art(); return "Form"; endfunction
endclass

class Rechner;
  localparam real PI = 3.141592653589793;
  localparam real EPS = 1.0e-9;
  localparam int MAX_SCHRITTE = 50;

  // Quadratwurzel nach Newton
  static function real wurzel(real v);
    real x, nx;
    if (v <= 0.0) return 0.0;
    x = v;
    for (int i = 0; i < MAX_SCHRITTE; i++) begin
      nx = 0.5 * (x + v / x);
      if ((nx > x ? nx - x : x - nx) < EPS) return nx;
      x = nx;
    end
    return x;
  endfunction

  static function int ggt(int a, int b);
    int r;
    while (b != 0) begin
      r = a % b;
      a = b;
      b = r;
    end
    return a;
  endfunction

  static function bit ist_prim(int n);
    if (n < 2) return 0;
    for (int t = 2; t * t <= n; t++)
      if (n % t == 0) return 0;
    return 1;
  endfunction

  static function string fmt(real x, int n);
    case (n)
      1: return $sformatf("%0.1f", x);
      2: return $sformatf("%0.2f", x);
      default: return $sformatf("%0.8f", x);
    endcase
  endfunction
endclass

class Kreis extends Form;
  local real r;
  function new(real r_); r = r_; endfunction
  virtual function real flaeche(); return Rechner::PI * r * r; endfunction
  virtual function real umfang(); return 2.0 * Rechner::PI * r; endfunction
  virtual function int ecken(); return 0; endfunction
  virtual function string art(); return "Kreis"; endfunction
endclass

class Rechteck extends Form;
  local real a, b;
  function new(real a_, real b_); a = a_; b = b_; endfunction
  virtual function real flaeche(); return a * b; endfunction
  virtual function real umfang(); return 2.0 * (a + b); endfunction
  virtual function int ecken(); return 4; endfunction
  virtual function string art(); return "Rechteck"; endfunction
endclass

class Dreieck extends Form;
  local real a, b, c;
  function new(real a_, real b_, real c_); a = a_; b = b_; c = c_; endfunction
  static function bit gueltig(real a, real b, real c);
    return (a + b > c) && (a + c > b) && (b + c > a);
  endfunction
  virtual function real flaeche();
    real s;
    s = (a + b + c) / 2.0;
    return Rechner::wurzel(s * (s - a) * (s - b) * (s - c));
  endfunction
  virtual function real umfang(); return a + b + c; endfunction
  virtual function int ecken(); return 3; endfunction
  virtual function string art(); return "Dreieck"; endfunction
endclass

module formen;
  Form formen_liste[$];
  Form tmp;
  Kreis k;
  Rechteck r;
  Dreieck d;
  initial begin
    $display("Formen-Rechner");
    k = new(2.5);
    formen_liste.push_back(k);
    r = new(4.0, 3.0);
    formen_liste.push_back(r);
    begin : dreiecke
      real werte[2][3] = '{'{3.0, 4.0, 5.0}, '{1.0, 2.0, 10.0}};   // TODO: weitere Formen
      foreach (werte[i]) begin
        if (Dreieck::gueltig(werte[i][0], werte[i][1], werte[i][2]))
        begin
          d = new(werte[i][0], werte[i][1], werte[i][2]);
          formen_liste.push_back(d);
        end
        else
          $display("Fehler: Dreieck %s/%s/%s ungueltig", Rechner::fmt(werte[i][0], 1),
                   Rechner::fmt(werte[i][1], 1), Rechner::fmt(werte[i][2], 1));
      end
    end
    // Sortieren nach Flaeche (Bubblesort)
    for (int i = 0; i < formen_liste.size() - 1; i++)
      for (int j = 0; j < formen_liste.size() - 1 - i; j++)
        if (formen_liste[j].flaeche() > formen_liste[j + 1].flaeche()) begin
          tmp = formen_liste[j];
          formen_liste[j] = formen_liste[j + 1];
          formen_liste[j + 1] = tmp;
        end
    foreach (formen_liste[i])
      $display("%s: Flaeche=%s Umfang=%s %s Ecken=%0d", formen_liste[i].art(),
               Rechner::fmt(formen_liste[i].flaeche(), 2), Rechner::fmt(formen_liste[i].umfang(), 2),
               formen_liste[i].flaeche() >= 10.0 ? "gross" : "klein", formen_liste[i].ecken());
    $display("ggT(48, 18) = %0d", Rechner::ggt(48, 18));
    begin : primzahlen
      string liste;
      liste = "";
      for (int n = 2; n <= 30; n++)
        if (Rechner::ist_prim(n)) liste = {liste, $sformatf(" %0d", n)};
      $display("Primzahlen bis 30:%s", liste);
    end
    $display("Wurzel(2) = %s", Rechner::fmt(Rechner::wurzel(2.0), 8));
    $display("Maske: %0d", 8'hFF & 8'b10101010);
    $display("Skala: %0d", 1_000_000 / 8);
    $finish(0);
  end
endmodule
