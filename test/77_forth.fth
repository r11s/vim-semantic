\ ------------------------------------------------------------------
\ Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
\ Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
\ gforth.  Starten: gforth 77_forth.fth -e bye
\ (Forth kennt weder Klassen noch Ausnahmen: Fehler = Pruefwort.)
\ ------------------------------------------------------------------
( Konstanten )
3.141592653589793e0 fconstant KREIS-PI
1e-9 fconstant EPS
50 constant MAX-SCHRITTE
0 constant KREIS  1 constant RECHTECK  2 constant DREIECK
4 constant MAX-FORMEN

\ Formentabelle: Art und drei Masse je Form
create ARTEN MAX-FORMEN cells allot
create MASSE MAX-FORMEN 3 * floats allot
create FLAECHEN MAX-FORMEN floats allot
create LISTE MAX-FORMEN cells allot     \ Indizes der gueltigen Formen
0 value anzahl

\ aktuelle Form (wird mit LADEN gesetzt)
variable part
fvariable pa  fvariable pb  fvariable pc  fvariable ps

: setze ( art i -- ) ( f: a b c -- )       \ Form i eintragen
    >r  r@ cells ARTEN + !
    r@ 3 * 2 + floats MASSE + f!
    r@ 3 * 1 + floats MASSE + f!
    r> 3 * floats MASSE + f! ;

: laden ( i -- )
    dup cells ARTEN + @ part !
    3 * floats MASSE +  dup f@ pa f!  float+ dup f@ pb f!  float+ f@ pc f! ;

\ Zahl mit n Nachkommastellen ausgeben
: .fix ( n -- ) ( f: x -- )
    dup >r  0 ?do 10e f* loop  fround f>s
    1 r@ 0 ?do 10 * loop
    /mod 0 .r  ." ."
    s>d <# r> 0 ?do # loop #> type ;

\ Quadratwurzel nach Newton:  ( f: v -- sqrt )
fvariable wv  fvariable wx
: wurzel
    fdup 0e f<= if fdrop 0e exit then
    fdup wv f!  wx f!
    MAX-SCHRITTE 0 do
        wv f@ wx f@ f/  wx f@ f+  0.5e f*              \ nx
        fdup wx f@ f- fabs EPS f< if  wx f!  leave  then
        wx f!
    loop
    wx f@ ;

: ggt ( a b -- g )  begin dup while tuck mod repeat drop ;

: ist-prim? ( n -- f )
    dup 2 < if drop false exit then
    dup 2 ?do
        i i * over > if leave then
        dup i mod 0= if drop false unloop exit then
    loop  drop true ;

: gueltig? ( -- f )
    part @ KREIS = if  pa f@ 0e f>  exit  then
    part @ RECHTECK = if  pa f@ 0e f>  pb f@ 0e f>  and  exit  then
    pa f@ pb f@ f+ pc f@ f>
    pa f@ pc f@ f+ pb f@ f>  and
    pb f@ pc f@ f+ pa f@ f>  and ;

: flaeche ( f: -- fl )
    part @ KREIS = if  pa f@ fdup f* KREIS-PI f*  exit  then
    part @ RECHTECK = if  pa f@ pb f@ f*  exit  then
    pa f@ pb f@ f+ pc f@ f+ 2e f/ ps f!
    ps f@ ps f@ pa f@ f- f*  ps f@ pb f@ f- f*  ps f@ pc f@ f- f*  wurzel ;

: umfang ( f: -- u )
    part @ KREIS = if  2e KREIS-PI f* pa f@ f*  exit  then
    part @ RECHTECK = if  pa f@ pb f@ f+ 2e f*  exit  then
    pa f@ pb f@ f+ pc f@ f+ ;

: ecken ( -- n )
    part @ case
        KREIS of 0 endof
        RECHTECK of 4 endof
        DREIECK of 3 endof
        -1 swap
    endcase ;

: .formname ( -- )
    part @ case
        KREIS of ." Kreis" endof
        RECHTECK of ." Rechteck" endof
        DREIECK of ." Dreieck" endof
    endcase ;

: .fehler ( -- )
    ." Fehler: " .formname space
    pa f@ 1 .fix
    part @ KREIS <> if ." /" pb f@ 1 .fix then
    part @ DREIECK = if ." /" pc f@ 1 .fix then
    ."  ungueltig" cr ;

: tausche ( j -- )                         \ LISTE[j] <-> LISTE[j+1]
    cells LISTE + dup @ over cell+ @ 2 pick ! swap cell+ ! ;
: fl-von ( j -- ) ( f: -- fl )  cells LISTE + @ floats FLAECHEN + f@ ;

: sortiere                                  \ Bubblesort nach Flaeche
    anzahl 1- 0 ?do
        anzahl 1- i - 0 ?do
            i fl-von  i 1+ fl-von  f> if i tausche then
        loop
    loop ;

: .zeile ( i -- )
    dup laden  .formname ." : Flaeche="
    floats FLAECHEN + f@ fdup 2 .fix
    ."  Umfang=" umfang 2 .fix
    space 10e f>= if ." gross" else ." klein" then   \ TODO: weitere Stufen
    ."  Ecken=" ecken 0 .r cr ;

: haupt
    ." Formen-Rechner" cr
    2.5e 0e 0e KREIS 0 setze
    4e 3e 0e RECHTECK 1 setze
    3e 4e 5e DREIECK 2 setze
    1e 2e 10e DREIECK 3 setze
    0 to anzahl
    MAX-FORMEN 0 do
        i laden
        gueltig? if
            flaeche  FLAECHEN anzahl floats + f!
            i LISTE anzahl cells + !
            anzahl 1+ to anzahl
        else .fehler then
    loop
    sortiere
    anzahl 0 ?do  LISTE i cells + @ .zeile  loop
    ." ggT(48, 18) = " 48 18 ggt 0 .r cr
    ." Primzahlen bis 30:"
    31 2 do i ist-prim? if space i 0 .r then loop cr
    ." Wurzel(2) = " 2e wurzel 8 .fix cr
    ." Maske: " $FF %10101010 and 0 .r cr
    ." Skala: " 1000000 8 / 0 .r cr ;

haupt
