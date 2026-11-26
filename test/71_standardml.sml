(* ------------------------------------------------------------------
   Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
   Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
   Standard ML (Poly/ML).  Starten: poly -q < 71_standardml.sml
   ------------------------------------------------------------------ *)
val pi = 3.141592653589793
val eps = 1E~9
val maxSchritte = 50

(* Eigene Ausnahme fuer ungueltige Masse *)
exception FormFehler of string

datatype form =
    Kreis of real
  | Rechteck of real * real
  | Dreieck of real * real * real

fun fmt (x, n) = Real.fmt (StringCvt.FIX (SOME n)) x

(* Quadratwurzel nach Newton *)
fun wurzel v =
  if v <= 0.0 then 0.0
  else
    let
      fun schritt (i, x) =
        let val nx = 0.5 * (x + v / x)
        in
          if Real.abs (nx - x) < eps orelse i >= maxSchritte then nx
          else schritt (i + 1, nx)
        end
    in
      schritt (0, v)
    end

fun name (Kreis _) = "Kreis"
  | name (Rechteck _) = "Rechteck"
  | name (Dreieck _) = "Dreieck"

(* Prueft die Masse; wirft FormFehler *)
fun pruefe f =
  let
    val (ok, masse) =
      case f of
          Kreis r => (r > 0.0, [r])
        | Rechteck (a, b) => (a > 0.0 andalso b > 0.0, [a, b])
        | Dreieck (a, b, c) =>
            (a + b > c andalso a + c > b andalso b + c > a, [a, b, c])
  in
    if ok then f
    else raise FormFehler (name f ^ " "
                           ^ String.concatWith "/" (map (fn x => fmt (x, 1)) masse)
                           ^ " ungueltig")
  end

fun flaeche (Kreis r) = pi * r * r
  | flaeche (Rechteck (a, b)) = a * b
  | flaeche (Dreieck (a, b, c)) =
      let val s = (a + b + c) / 2.0
      in wurzel (s * (s - a) * (s - b) * (s - c)) end

fun umfang (Kreis r) = 2.0 * pi * r
  | umfang (Rechteck (a, b)) = 2.0 * (a + b)
  | umfang (Dreieck (a, b, c)) = a + b + c

fun ecken (Kreis _) = 0
  | ecken (Rechteck _) = 4
  | ecken (Dreieck _) = 3

fun ggt (a, 0) = a
  | ggt (a, b) = ggt (b, a mod b)

fun istPrim n =
  let
    fun pruefeTeiler t =
      if t * t > n then true
      else if n mod t = 0 then false
      else pruefeTeiler (t + 1)
  in
    n >= 2 andalso pruefeTeiler 2
  end

fun zeile f =
  name f ^ ": Flaeche=" ^ fmt (flaeche f, 2) ^ " Umfang=" ^ fmt (umfang f, 2) ^ " "
  ^ (if flaeche f >= 10.0 then "gross" else "klein")
  ^ " Ecken=" ^ Int.toString (ecken f)

fun einfuegen (x, []) = [x]
  | einfuegen (x, y :: ys) =
      if flaeche x <= flaeche y then x :: y :: ys else y :: einfuegen (x, ys)

val sortiere = foldl einfuegen []

fun versuche wunsch =
  SOME (wunsch ()) handle FormFehler meldung =>
    (print ("Fehler: " ^ meldung ^ "\n"); NONE)

val _ = print "Formen-Rechner\n"
val wuensche = [
  fn () => pruefe (Kreis 2.5),
  fn () => pruefe (Rechteck (4.0, 3.0)),
  fn () => pruefe (Dreieck (3.0, 4.0, 5.0)),
  fn () => pruefe (Dreieck (1.0, 2.0, 10.0))   (* TODO: weitere Formen *)
]
val formen = List.mapPartial versuche wuensche
val _ = app (fn f => print (zeile f ^ "\n")) (sortiere formen)
val _ = print ("ggT(48, 18) = " ^ Int.toString (ggt (48, 18)) ^ "\n")
val primzahlen = List.filter istPrim (List.tabulate (29, fn i => i + 2))
val _ = print ("Primzahlen bis 30: " ^ String.concatWith " " (map Int.toString primzahlen) ^ "\n")
val _ = print ("Wurzel(2) = " ^ fmt (wurzel 2.0, 8) ^ "\n")
val _ = print ("Maske: " ^ Word.fmt StringCvt.DEC (Word.andb (0wxFF, 0wxAA)) ^ "\n")
val _ = print ("Skala: " ^ Int.toString (1000000 div 8) ^ "\n")
