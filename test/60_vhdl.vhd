-- ------------------------------------------------------------------
-- Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
-- Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
-- Simulation: ghdl -a --std=08 60_vhdl.vhd && ghdl -e --std=08 formen \
--             && ghdl -r --std=08 formen
-- ------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use std.textio.all;

entity formen is
end entity formen;

architecture test of formen is
  constant PI           : real    := 3.141592653589793;
  constant EPS          : real    := 1.0e-9;
  constant MAX_SCHRITTE : integer := 50;

  type art_t is (kreis, rechteck, dreieck);
  type form_t is record
    art : art_t;
    a, b, c : real;
  end record;
  type form_liste is array (natural range <>) of form_t;

  -- Zahl mit n Nachkommastellen als Text (ohne Bibliothek-Formatierung)
  function fmt(x : real; n : natural) return string is
    variable skal : integer := 10 ** n;
    variable wert : integer := integer(round(x * real(skal)));
    variable ganz : integer := wert / skal;
    variable rest : integer := wert mod skal;
    variable rtext : string(1 to n);
  begin
    for i in n downto 1 loop
      rtext(i) := character'val(character'pos('0') + (rest mod 10));
      rest := rest / 10;
    end loop;
    return to_string(ganz) & "." & rtext;
  end function;

  -- Quadratwurzel nach Newton
  function wurzel(v : real) return real is
    variable x, nx : real;
  begin
    if v <= 0.0 then
      return 0.0;
    end if;
    x := v;
    for i in 1 to MAX_SCHRITTE loop
      nx := 0.5 * (x + v / x);
      if abs (nx - x) < EPS then
        return nx;
      end if;
      x := nx;
    end loop;
    return x;
  end function;

  function gueltig(f : form_t) return boolean is
  begin
    case f.art is
      when kreis    => return f.a > 0.0;
      when rechteck => return f.a > 0.0 and f.b > 0.0;
      when dreieck  => return f.a + f.b > f.c and f.a + f.c > f.b and f.b + f.c > f.a;
    end case;
  end function;

  function flaeche(f : form_t) return real is
    variable s : real;
  begin
    case f.art is
      when kreis    => return PI * f.a * f.a;
      when rechteck => return f.a * f.b;
      when dreieck  =>
        s := (f.a + f.b + f.c) / 2.0;
        return wurzel(s * (s - f.a) * (s - f.b) * (s - f.c));
    end case;
  end function;

  function umfang(f : form_t) return real is
  begin
    case f.art is
      when kreis    => return 2.0 * PI * f.a;
      when rechteck => return 2.0 * (f.a + f.b);
      when dreieck  => return f.a + f.b + f.c;
    end case;
  end function;

  function ecken(f : form_t) return integer is
  begin
    case f.art is
      when kreis    => return 0;
      when rechteck => return 4;
      when dreieck  => return 3;
    end case;
  end function;

  function ggt(x, y : integer) return integer is
    variable a : integer := x;
    variable b : integer := y;
    variable r : integer;
  begin
    while b /= 0 loop
      r := a mod b; a := b; b := r;
    end loop;
    return a;
  end function;

  function ist_prim(n : integer) return boolean is
    variable t : integer := 2;
  begin
    if n < 2 then return false; end if;
    while t * t <= n loop
      if n mod t = 0 then return false; end if;
      t := t + 1;
    end loop;
    return true;
  end function;

  function name(a : art_t) return string is
  begin
    case a is
      when kreis    => return "Kreis";
      when rechteck => return "Rechteck";
      when dreieck  => return "Dreieck";
    end case;
  end function;
begin
  hauptprogramm : process
    variable l : line;
    variable alle : form_liste(0 to 3) := (
      (kreis, 2.5, 0.0, 0.0), (rechteck, 4.0, 3.0, 0.0),
      (dreieck, 3.0, 4.0, 5.0), (dreieck, 1.0, 2.0, 10.0));  -- TODO: weitere Formen
    variable ok : form_liste(0 to 3);
    variable n : natural := 0;
    variable tmp : form_t;
    variable m : integer;
  begin
    write(l, string'("Formen-Rechner"));
    writeline(output, l);
    for i in alle'range loop
      if gueltig(alle(i)) then
        ok(n) := alle(i);
        n := n + 1;
      else
        write(l, "Fehler: " & name(alle(i).art) & " " & fmt(alle(i).a, 1) & "/" &
                 fmt(alle(i).b, 1) & "/" & fmt(alle(i).c, 1) & " ungueltig");
        writeline(output, l);
      end if;
    end loop;
    -- Sortieren nach Flaeche (Bubblesort)
    for i in 0 to n - 2 loop
      for j in 0 to n - 2 - i loop
        if flaeche(ok(j)) > flaeche(ok(j + 1)) then
          tmp := ok(j); ok(j) := ok(j + 1); ok(j + 1) := tmp;
        end if;
      end loop;
    end loop;
    for i in 0 to n - 1 loop
      write(l, name(ok(i).art) & ": Flaeche=" & fmt(flaeche(ok(i)), 2) &
               " Umfang=" & fmt(umfang(ok(i)), 2));
      if flaeche(ok(i)) >= 10.0 then write(l, string'(" gross")); else write(l, string'(" klein")); end if;
      write(l, " Ecken=" & to_string(ecken(ok(i))));
      writeline(output, l);
    end loop;
    write(l, "ggT(48, 18) = " & to_string(ggt(48, 18)));
    writeline(output, l);
    write(l, string'("Primzahlen bis 30:"));
    for p in 2 to 30 loop
      if ist_prim(p) then write(l, " " & to_string(p)); end if;
    end loop;
    writeline(output, l);
    write(l, "Wurzel(2) = " & fmt(wurzel(2.0), 8));
    writeline(output, l);
    m := to_integer(unsigned'(x"FF") and unsigned'("10101010"));
    write(l, "Maske: " & to_string(m));
    writeline(output, l);
    write(l, "Skala: " & to_string(1000000 / 8));
    writeline(output, l);
    wait;
  end process;
end architecture test;
