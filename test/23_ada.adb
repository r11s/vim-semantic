-- ------------------------------------------------------------------
-- Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
-- Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
-- Bauen: gnatchop -w 23_ada.adb && gnatmake -gnat2012 formen
--        (gnatchop benennt die Datei passend zur Einheit "Formen" um)
-- ------------------------------------------------------------------
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Text_IO; use Ada.Text_IO;

procedure Formen is

   type Gleitzahl is new Long_Float;
   package Gleit_IO is new Ada.Text_IO.Float_IO (Gleitzahl);

   Pi           : constant Gleitzahl := 3.141592653589793;  -- Kreiszahl
   Eps          : constant Gleitzahl := 1.0E-9;             -- Abbruch bei Newton
   Max_Schritte : constant := 50;
   type Byte is mod 2 ** 8;
   Maske        : constant Byte := 16#FF# and 2#1010_1010#; -- Basis-Literale
   Skala        : constant := 1_000_000 / 8;                -- Ganzzahldivision

   --  Wird ausgeloest, wenn Masse keine gueltige Figur ergeben.
   Form_Fehler : exception;

   function Image (N : Integer) return String is
     (Ada.Strings.Fixed.Trim (Integer'Image (N), Ada.Strings.Left));

   function Text (X : Gleitzahl; Aft : Natural) return String is
      Puffer : String (1 .. 32);
   begin
      Gleit_IO.Put (Puffer, X, Aft => Aft, Exp => 0);
      return Ada.Strings.Fixed.Trim (Puffer, Ada.Strings.Left);
   end Text;

   --  Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
   function Wurzel (X : Gleitzahl) return Gleitzahl is
      Alt : Gleitzahl := X;
      Neu : Gleitzahl;
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      for Schritt in 1 .. Max_Schritte loop
         Neu := 0.5 * (Alt + X / Alt);
         if abs (Neu - Alt) < Eps then
            return Neu;
         end if;
         Alt := Neu;
      end loop;
      return Alt;
   end Wurzel;

   --  Groesster gemeinsamer Teiler nach Euklid.
   function Ggt (A0, B0 : Natural) return Natural is
      A    : Natural := A0;
      B    : Natural := B0;
      Rest : Natural;
   begin
      while B /= 0 loop
         Rest := A mod B;
         A := B;
         B := Rest;
      end loop;
      return A;
   end Ggt;

   --  Primzahltest durch Probedivision bis zur Wurzel von N.
   function Ist_Prim (N : Natural) return Boolean is
      I : Natural := 2;
   begin
      if N < 2 then
         return False;
      end if;
      while I * I <= N loop
         if N mod I = 0 then
            return False;
         end if;
         I := I + 1;
      end loop;
      return True;
   end Ist_Prim;

   --  Primitive Operationen getaggter Typen gehoeren in eine Paketspezifikation.
   package Typen is
      --  Gemeinsame Basis aller Formen.
      type Figur is abstract tagged null record;
      function Name (F : Figur) return String is abstract;
      function Flaeche (F : Figur) return Gleitzahl is abstract;
      function Umfang (F : Figur) return Gleitzahl is abstract;
      type Figur_Zeiger is access Figur'Class;

      type Kreis is new Figur with record
         R : Gleitzahl;
      end record;
      overriding function Name (K : Kreis) return String is ("Kreis");
      overriding function Flaeche (K : Kreis) return Gleitzahl is (Pi * K.R ** 2);
      overriding function Umfang (K : Kreis) return Gleitzahl is (2.0 * Pi * K.R);

      type Rechteck is new Figur with record
         Breite, Hoehe : Gleitzahl;
      end record;
      overriding function Name (R : Rechteck) return String is ("Rechteck");
      overriding function Flaeche (R : Rechteck) return Gleitzahl is (R.Breite * R.Hoehe);
      overriding function Umfang (R : Rechteck) return Gleitzahl is (2.0 * (R.Breite + R.Hoehe));

      type Dreieck is new Figur with record
         A, B, C : Gleitzahl;
      end record;
      overriding function Name (D : Dreieck) return String is ("Dreieck");
      overriding function Umfang (D : Dreieck) return Gleitzahl is (D.A + D.B + D.C);
      overriding function Flaeche (D : Dreieck) return Gleitzahl;
   end Typen;

   package body Typen is
      overriding function Flaeche (D : Dreieck) return Gleitzahl is
         S : constant Gleitzahl := Umfang (D) / 2.0;  -- Satz des Heron
      begin
         return Wurzel (S * (S - D.A) * (S - D.B) * (S - D.C));
      end Flaeche;
   end Typen;
   use Typen;

   function Neuer_Kreis (R : Gleitzahl) return Figur_Zeiger is
   begin
      if R <= 0.0 then
         raise Form_Fehler with "Kreis " & Text (R, 1) & " ungueltig";
      end if;
      return new Kreis'(R => R);
   end Neuer_Kreis;

   function Neues_Rechteck (B, H : Gleitzahl) return Figur_Zeiger is
   begin
      if B <= 0.0 or H <= 0.0 then
         raise Form_Fehler with "Rechteck " & Text (B, 1) & "/" & Text (H, 1) & " ungueltig";
      end if;
      return new Rechteck'(Breite => B, Hoehe => H);
   end Neues_Rechteck;

   function Neues_Dreieck (A, B, C : Gleitzahl) return Figur_Zeiger is
   begin
      if A + B <= C or A + C <= B or B + C <= A then
         raise Form_Fehler with
           "Dreieck " & Text (A, 1) & "/" & Text (B, 1) & "/" & Text (C, 1) & " ungueltig";
      end if;
      return new Dreieck'(A => A, B => B, C => C);
   end Neues_Dreieck;

   function Ecken (F : Figur'Class) return Integer is
   begin
      if F in Dreieck then
         return 3;
      elsif F in Rechteck then
         return 4;
      elsif F in Kreis then
         return 0;
      else
         return -1;
      end if;
   end Ecken;

   Liste  : array (1 .. 4) of Figur_Zeiger;
   Anzahl : Natural := 0;
   Tausch : Figur_Zeiger;

   procedure Hinzu (F : Figur_Zeiger) is
   begin
      Anzahl := Anzahl + 1;
      Liste (Anzahl) := F;
   end Hinzu;

begin
   Put_Line ("Formen-Rechner");
   begin
      Hinzu (Neuer_Kreis (2.5));
      Hinzu (Neues_Rechteck (4.0, 3.0));
      Hinzu (Neues_Dreieck (3.0, 4.0, 5.0));
      Hinzu (Neues_Dreieck (1.0, 2.0, 10.0));  -- TODO: weitere Formen
   exception
      when Fehler : Form_Fehler =>
         Put_Line ("Fehler: " & Ada.Exceptions.Exception_Message (Fehler));
   end;

   for I in 1 .. Anzahl - 1 loop              -- Sortieren nach Flaeche
      for J in 1 .. Anzahl - I loop
         if Flaeche (Liste (J).all) > Flaeche (Liste (J + 1).all) then
            Tausch := Liste (J);
            Liste (J) := Liste (J + 1);
            Liste (J + 1) := Tausch;
         end if;
      end loop;
   end loop;

   for I in 1 .. Anzahl loop
      declare
         F      : Figur'Class renames Liste (I).all;
         Status : constant String := (if Flaeche (F) >= 10.0 then "gross" else "klein");
      begin
         Put_Line (Name (F) & ": Flaeche=" & Text (Flaeche (F), 2)
                   & " Umfang=" & Text (Umfang (F), 2)
                   & " " & Status & " Ecken=" & Image (Ecken (F)));
      end;
   end loop;

   Put_Line ("ggT(48, 18) = " & Image (Ggt (48, 18)));
   Put ("Primzahlen bis 30:");
   for N in 2 .. 30 loop
      if Ist_Prim (N) then
         Put (" " & Image (N));
      end if;
   end loop;
   New_Line;
   Put_Line ("Wurzel(2) = " & Text (Wurzel (2.0), 8));
   Put_Line ("Maske: " & Image (Integer (Maske)));
   Put_Line ("Skala: " & Image (Skala));
end Formen;
