port module Main exposing (main)

{-| ------------------------------------------------------------------
Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
Elm 0.19: keine Ausnahmen (Result statt throw), keine Klassen (Custom Types).
Bauen: elm make 98_elm.elm --output=elm.js  (siehe README zum Ausfuehren)
------------------------------------------------------------------
-}

import Bitwise


-- KONSTANTEN


pi_ : Float
pi_ =
    3.141592653589793


eps : Float
eps =
    1.0e-9


maxSchritte : Int
maxSchritte =
    50


port salida : String -> Cmd msg


-- TYPEN


type Form
    = Kreis Float
    | Rechteck Float Float
    | Dreieck Float Float Float


type alias FormFehler =
    String


fmt : Int -> Float -> String
fmt n x =
    let
        skal =
            10 ^ n

        wert =
            round (x * toFloat skal)

        ganz =
            wert // skal

        rest =
            String.padLeft n '0' (String.fromInt (modBy skal wert))
    in
    String.fromInt ganz ++ "." ++ rest


{-| Quadratwurzel nach Newton. -}
wurzel : Float -> Float
wurzel v =
    let
        schritt i x =
            let
                nx =
                    0.5 * (x + v / x)
            in
            if abs (nx - x) < eps || i >= maxSchritte then
                nx

            else
                schritt (i + 1) nx
    in
    if v <= 0 then
        0

    else
        schritt 0 v


name : Form -> String
name f =
    case f of
        Kreis _ ->
            "Kreis"

        Rechteck _ _ ->
            "Rechteck"

        Dreieck _ _ _ ->
            "Dreieck"


-- Prueft die Masse; Err enthaelt die Fehlermeldung
pruefe : Form -> Result FormFehler Form
pruefe f =
    let
        melde masse =
            Err (name f ++ " " ++ String.join "/" (List.map (fmt 1) masse) ++ " ungueltig")
    in
    case f of
        Kreis r ->
            if r > 0 then Ok f else melde [ r ]

        Rechteck a b ->
            if a > 0 && b > 0 then Ok f else melde [ a, b ]

        Dreieck a b c ->
            if a + b > c && a + c > b && b + c > a then Ok f else melde [ a, b, c ]


flaeche : Form -> Float
flaeche f =
    case f of
        Kreis r ->
            pi_ * r * r

        Rechteck a b ->
            a * b

        Dreieck a b c ->
            let
                s =
                    (a + b + c) / 2
            in
            wurzel (s * (s - a) * (s - b) * (s - c))


umfang : Form -> Float
umfang f =
    case f of
        Kreis r ->
            2 * pi_ * r

        Rechteck a b ->
            2 * (a + b)

        Dreieck a b c ->
            a + b + c


ecken : Form -> Int
ecken f =
    case f of
        Kreis _ ->
            0

        Rechteck _ _ ->
            4

        Dreieck _ _ _ ->
            3


ggt : Int -> Int -> Int
ggt a b =
    if b == 0 then
        a

    else
        ggt b (modBy b a)


istPrim : Int -> Bool
istPrim n =
    let
        pruefeTeiler t =
            if t * t > n then
                True

            else if modBy t n == 0 then
                False

            else
                pruefeTeiler (t + 1)
    in
    n >= 2 && pruefeTeiler 2


zeile : Form -> String
zeile f =
    let
        status =
            if flaeche f >= 10.0 then
                "gross"

            else
                "klein"
    in
    name f
        ++ ": Flaeche="
        ++ fmt 2 (flaeche f)
        ++ " Umfang="
        ++ fmt 2 (umfang f)
        ++ " "
        ++ status
        ++ " Ecken="
        ++ String.fromInt (ecken f)


ausgabe : List String
ausgabe =
    let
        ergebnisse =
            List.map pruefe
                [ Kreis 2.5
                , Rechteck 4.0 3.0
                , Dreieck 3.0 4.0 5.0
                , Dreieck 1.0 2.0 10.0 -- TODO: weitere Formen
                ]

        fehler =
            List.filterMap
                (\r ->
                    case r of
                        Err m ->
                            Just ("Fehler: " ++ m)

                        Ok _ ->
                            Nothing
                )
                ergebnisse

        gueltig =
            List.filterMap Result.toMaybe ergebnisse
    in
    [ "Formen-Rechner" ]
        ++ fehler
        ++ List.map zeile (List.sortBy flaeche gueltig)
        ++ [ "ggT(48, 18) = " ++ String.fromInt (ggt 48 18)
           , "Primzahlen bis 30: " ++ String.join " " (List.map String.fromInt (List.filter istPrim (List.range 2 30)))
           , "Wurzel(2) = " ++ fmt 8 (wurzel 2.0)
           , "Maske: " ++ String.fromInt (Bitwise.and 0xFF 170)
           , "Skala: " ++ String.fromInt (1000000 // 8)
           ]


main : Program () () ()
main =
    Platform.worker
        { init = \_ -> ( (), salida (String.join "\n" ausgabe) )
        , update = \_ m -> ( m, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }
