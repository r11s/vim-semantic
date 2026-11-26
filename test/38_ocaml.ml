(* ------------------------------------------------------------------
   Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
   Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
   Start: ocaml 38_ocaml.ml
   ------------------------------------------------------------------ *)

let kreiszahl = 3.141592653589793   (* Kreiszahl *)
let eps = 1e-9                      (* Abbruchschwelle fuer Newton *)
let max_schritte = 50
let maske = 0xFF land 0b10101010    (* Hex- und Binaerliteral *)
let skala = 1_000_000 / 8

(** Wird ausgeloest, wenn Masse keine gueltige Form ergeben. *)
exception Form_fehler of string

(** Quadratwurzel nach Newton: neu = (alt + x / alt) / 2. *)
let wurzel x =
  if x <= 0.0 then 0.0
  else
    let rec schritt i alt =
      let neu = 0.5 *. (alt +. x /. alt) in
      if i >= max_schritte then alt
      else if abs_float (neu -. alt) < eps then neu
      else schritt (i + 1) neu
    in
    schritt 0 x

(** Groesster gemeinsamer Teiler nach Euklid. *)
let rec ggt a b = if b = 0 then a else ggt b (a mod b)

(** Primzahltest durch Probedivision bis zur Wurzel von n. *)
let ist_prim n =
  let rec teste i = i * i > n || (n mod i <> 0 && teste (i + 1)) in
  n >= 2 && teste 2

(** Gemeinsame Basisklasse aller Formen. *)
class virtual form =
  object
    method virtual name : string
    method virtual flaeche : float
    method virtual umfang : float
  end

class kreis r =
  object
    inherit form
    initializer if r <= 0.0 then raise (Form_fehler (Printf.sprintf "Kreis %.1f ungueltig" r))
    method name = "Kreis"
    method flaeche = kreiszahl *. r *. r
    method umfang = 2.0 *. kreiszahl *. r
  end

class rechteck breite hoehe =
  object
    inherit form
    initializer
      if breite <= 0.0 || hoehe <= 0.0 then
        raise (Form_fehler (Printf.sprintf "Rechteck %.1f/%.1f ungueltig" breite hoehe))
    method name = "Rechteck"
    method flaeche = breite *. hoehe
    method umfang = 2.0 *. (breite +. hoehe)
  end

class dreieck a b c =
  object (self)
    inherit form
    initializer
      if a +. b <= c || a +. c <= b || b +. c <= a then
        raise (Form_fehler (Printf.sprintf "Dreieck %.1f/%.1f/%.1f ungueltig" a b c))
    method name = "Dreieck"
    method umfang = a +. b +. c
    method flaeche =
      let s = self#umfang /. 2.0 in   (* Satz des Heron *)
      wurzel (s *. (s -. a) *. (s -. b) *. (s -. c))
  end

let ecken (f : form) =
  match f#name with
  | "Dreieck" -> 3
  | "Rechteck" -> 4
  | "Kreis" -> 0
  | _ -> -1

let () =
  print_endline "Formen-Rechner";
  let formen = ref [ (new kreis 2.5 :> form); (new rechteck 4.0 3.0 :> form); (new dreieck 3.0 4.0 5.0 :> form) ] in
  (try formen := (new dreieck 1.0 2.0 10.0 :> form) :: !formen   (* TODO: weitere Formen *)
   with Form_fehler meldung -> Printf.printf "Fehler: %s\n" meldung);
  let sortiert = List.sort (fun x y -> compare x#flaeche y#flaeche) !formen in
  List.iter
    (fun f ->
      let status = if f#flaeche >= 10.0 then "gross" else "klein" in
      Printf.printf "%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n" f#name f#flaeche f#umfang status (ecken f))
    sortiert;
  Printf.printf "ggT(48, 18) = %d\n" (ggt 48 18);
  let prim = List.filter ist_prim (List.init 29 (fun i -> i + 2)) in
  Printf.printf "Primzahlen bis 30: %s\n" (String.concat " " (List.map string_of_int prim));
  Printf.printf "Wurzel(2) = %.8f\n" (wurzel 2.0);
  Printf.printf "Maske: %d\n" maske;
  Printf.printf "Skala: %d\n" skala
