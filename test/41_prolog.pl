%   Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
%
%   Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
%   Start: swipl -q -g main -t halt 41_prolog.pl

:- use_module(library(lists)).
:- use_module(library(apply)).

/* Konstanten als Fakten */
kreiszahl(3.141592653589793).      % Kreiszahl
eps(1.0e-9).                       % Abbruchschwelle fuer Newton
max_schritte(50).
maske(M) :- M is 0xFF /\ 0b10101010.   % Hex- und Binaerliteral
skala(S) :- S is 1_000_000 // 8.

%!  wurzel(+X, -W) is det.
%   Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
wurzel(X, 0.0) :- X =< 0, !.
wurzel(X, W) :- schritt(X, X, 0, W).

schritt(_, Alt, I, Alt) :- max_schritte(Max), I >= Max, !.
schritt(X, Alt, I, W) :-
    Neu is 0.5 * (Alt + X / Alt),
    eps(Eps),
    (   abs(Neu - Alt) < Eps
    ->  W = Neu
    ;   I1 is I + 1,
        schritt(X, Neu, I1, W)
    ).

%!  ggt(+A, +B, -G) is det.
ggt(A, 0, A) :- !.
ggt(A, B, G) :- R is A mod B, ggt(B, R, G).

%!  ist_prim(+N) is semidet.
ist_prim(N) :- N >= 2, \+ hat_teiler(N, 2).
hat_teiler(N, I) :- I * I =< N, ( N mod I =:= 0 -> true ; I1 is I + 1, hat_teiler(N, I1) ).

% Formen als Terme: kreis(R), rechteck(B, H), dreieck(A, B, C)
neue_form(kreis(R), _) :- R =< 0, !, fehler("Kreis ~1f ungueltig", [R]).
neue_form(rechteck(B, H), _) :- ( B =< 0 ; H =< 0 ), !, fehler("Rechteck ~1f/~1f ungueltig", [B, H]).
neue_form(dreieck(A, B, C), _) :-
    ( A + B =< C ; A + C =< B ; B + C =< A ), !,
    fehler("Dreieck ~1f/~1f/~1f ungueltig", [A, B, C]).
neue_form(Form, Form).

fehler(Muster, Args) :- format(string(Text), Muster, Args), throw(form_fehler(Text)).

name(kreis(_), "Kreis").
name(rechteck(_, _), "Rechteck").
name(dreieck(_, _, _), "Dreieck").

flaeche(kreis(R), F) :- kreiszahl(Pi), F is Pi * R * R.
flaeche(rechteck(B, H), F) :- F is B * H.
flaeche(dreieck(A, B, C), F) :-
    S is (A + B + C) / 2,          % Satz des Heron
    wurzel(S * (S - A) * (S - B) * (S - C), F).

umfang(kreis(R), U) :- kreiszahl(Pi), U is 2 * Pi * R.
umfang(rechteck(B, H), U) :- U is 2 * (B + H).
umfang(dreieck(A, B, C), U) :- U is A + B + C.

ecken(Form, E) :- name(Form, N), ( N == "Dreieck" -> E = 3 ; N == "Rechteck" -> E = 4 ; N == "Kreis" -> E = 0 ; E = -1 ).

mit_flaeche(Form, F-Form) :- flaeche(Form, F).

zeige(_-Form) :-
    name(Form, N), flaeche(Form, F), umfang(Form, U), ecken(Form, E),
    ( F >= 10.0 -> Status = gross ; Status = klein ),
    format("~s: Flaeche=~2f Umfang=~2f ~w Ecken=~d~n", [N, F, U, Status, E]).

main :-
    format("Formen-Rechner~n"),
    Kandidaten = [kreis(2.5), rechteck(4.0, 3.0), dreieck(3.0, 4.0, 5.0), dreieck(1.0, 2.0, 10.0)],  % TODO: weitere Formen
    foldl([K, Alt, Neu]>>(
              catch(( neue_form(K, _), Neu = [K|Alt] ),
                    form_fehler(Text), ( format("Fehler: ~s~n", [Text]), Neu = Alt ))),
          Kandidaten, [], Formen),
    maplist(mit_flaeche, Formen, Paare),
    keysort(Paare, Sortiert),
    maplist(zeige, Sortiert),
    ggt(48, 18, G), format("ggT(48, 18) = ~d~n", [G]),
    numlist(2, 30, Zahlen), include(ist_prim, Zahlen, Prim),
    atomic_list_concat(Prim, ' ', PrimText), format("Primzahlen bis 30: ~w~n", [PrimText]),
    wurzel(2, W), format("Wurzel(2) = ~8f~n", [W]),
    maske(M), format("Maske: ~d~n", [M]),
    skala(S), format("Skala: ~d~n", [S]).
