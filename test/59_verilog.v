// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
// Simulation: iverilog -g2012 -o formen 59_verilog.v && vvp formen
// (Verilog kennt weder Klassen noch Ausnahmen: Fehler = Rueckgabecode.)
// ------------------------------------------------------------------
`timescale 1ns/1ps
`define PI 3.141592653589793
`define EPS 1.0e-9
`define MAX_SCHRITTE 50

module formen;
  /* Formarten als Konstanten */
  localparam KREIS = 0, RECHTECK = 1, DREIECK = 2;

  integer art [0:3];
  real    ma  [0:3];
  real    mb  [0:3];
  real    mc  [0:3];
  real    fl  [0:3];
  integer gueltig [0:3];
  integer anzahl, i, j, tmp;

  // Quadratwurzel nach Newton
  function real wurzel(input real v);
    real x, nx;
    integer k;
    reg fertig;
    begin
      if (v <= 0.0) wurzel = 0.0;
      else begin
        x = v;
        fertig = 0;
        for (k = 0; k < `MAX_SCHRITTE && !fertig; k = k + 1) begin
          nx = 0.5 * (x + v / x);
          if ((nx > x ? nx - x : x - nx) < `EPS) fertig = 1;
          x = nx;
        end
        wurzel = x;
      end
    end
  endfunction

  // Gibt 1 zurueck, wenn die Masse der Form n gueltig sind
  function integer pruefe(input integer n);
    begin
      pruefe = 1;
      case (art[n])
        KREIS:    if (ma[n] <= 0.0) pruefe = 0;
        RECHTECK: if (ma[n] <= 0.0 || mb[n] <= 0.0) pruefe = 0;
        DREIECK:  if (ma[n] + mb[n] <= mc[n] || ma[n] + mc[n] <= mb[n]
                      || mb[n] + mc[n] <= ma[n]) pruefe = 0;
      endcase
    end
  endfunction

  function real flaeche(input integer n);
    real s;
    begin
      case (art[n])
        KREIS:    flaeche = `PI * ma[n] * ma[n];
        RECHTECK: flaeche = ma[n] * mb[n];
        default: begin
          s = (ma[n] + mb[n] + mc[n]) / 2.0;
          flaeche = wurzel(s * (s - ma[n]) * (s - mb[n]) * (s - mc[n]));
        end
      endcase
    end
  endfunction

  function real umfang(input integer n);
    case (art[n])
      KREIS:    umfang = 2.0 * `PI * ma[n];
      RECHTECK: umfang = 2.0 * (ma[n] + mb[n]);
      default:  umfang = ma[n] + mb[n] + mc[n];
    endcase
  endfunction

  function integer ecken(input integer n);
    case (art[n])
      KREIS:    ecken = 0;
      RECHTECK: ecken = 4;
      DREIECK:  ecken = 3;
      default:  ecken = -1;
    endcase
  endfunction

  function integer ggt(input integer a0, input integer b0);
    integer a, b, r;
    begin
      a = a0; b = b0;
      while (b != 0) begin r = a % b; a = b; b = r; end
      ggt = a;
    end
  endfunction

  function integer ist_prim(input integer n);
    integer t;
    begin
      ist_prim = (n >= 2);
      for (t = 2; t * t <= n; t = t + 1)
        if (n % t == 0) ist_prim = 0;
    end
  endfunction

  task setze(input integer n, input integer a, input real x, input real y, input real z);
    begin art[n] = a; ma[n] = x; mb[n] = y; mc[n] = z; end
  endtask

  initial begin
    $display("Formen-Rechner");
    setze(0, KREIS, 2.5, 0.0, 0.0);
    setze(1, RECHTECK, 4.0, 3.0, 0.0);
    setze(2, DREIECK, 3.0, 4.0, 5.0);
    setze(3, DREIECK, 1.0, 2.0, 10.0);   // TODO: weitere Formen
    anzahl = 0;
    for (i = 0; i < 4; i = i + 1) begin
      if (pruefe(i)) begin
        gueltig[anzahl] = i;
        fl[anzahl] = flaeche(i);
        anzahl = anzahl + 1;
      end else
        $display("Fehler: Dreieck %0.1f/%0.1f/%0.1f ungueltig", ma[i], mb[i], mc[i]);
    end
    // Sortieren nach Flaeche (Bubblesort)
    for (i = 0; i < anzahl - 1; i = i + 1)
      for (j = 0; j < anzahl - 1 - i; j = j + 1)
        if (fl[j] > fl[j + 1]) begin
          tmp = gueltig[j]; gueltig[j] = gueltig[j + 1]; gueltig[j + 1] = tmp;
          fl[3] = fl[j]; fl[j] = fl[j + 1]; fl[j + 1] = fl[3];
        end
    for (i = 0; i < anzahl; i = i + 1) begin
      j = gueltig[i];
      case (art[j])
        KREIS:    $write("Kreis: ");
        RECHTECK: $write("Rechteck: ");
        default:  $write("Dreieck: ");
      endcase
      $display("Flaeche=%0.2f Umfang=%0.2f %0s Ecken=%0d", fl[i], umfang(j),
               (fl[i] >= 10.0) ? "gross" : "klein", ecken(j));
    end
    $display("ggT(48, 18) = %0d", ggt(48, 18));
    $write("Primzahlen bis 30:");
    for (i = 2; i <= 30; i = i + 1) if (ist_prim(i)) $write(" %0d", i);
    $write("\n");
    $display("Wurzel(2) = %0.8f", wurzel(2.0));
    $display("Maske: %0d", 8'hFF & 8'b10101010);
    $display("Skala: %0d", 1_000_000 / 8);
    $finish(0);
  end
endmodule
