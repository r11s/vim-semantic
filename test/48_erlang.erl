%%% ------------------------------------------------------------------
%%% Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
%%% Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
%%% Starten: escript 48_erlang.erl
%%% ------------------------------------------------------------------
-module(formen).
-export([main/1]).

-define(PI, 3.141592653589793).
-define(EPS, 1.0e-9).
-define(MAX_SCHRITTE, 50).

%% @doc Form als Tupel: {Art, Masse}. Ungueltige Masse werfen einen Fehler.
-spec pruefe({atom(), [float()]}) -> ok.
pruefe({kreis, [R]}) when R > 0 -> ok;
pruefe({rechteck, [A, B]}) when A > 0, B > 0 -> ok;
pruefe({dreieck, [A, B, C]}) when A + B > C, A + C > B, B + C > A -> ok;
pruefe({Art, Masse}) ->
    Texte = [fmt(M, 1) || M <- Masse],
    throw({ungueltig, io_lib:format("~s ~s ungueltig",
        [name(Art), lists:join("/", Texte)])}).

name(kreis) -> "Kreis";
name(rechteck) -> "Rechteck";
name(dreieck) -> "Dreieck".

fmt(Zahl, Stellen) ->
    lists:flatten(io_lib:format("~.*f", [Stellen, Zahl])).

flaeche({kreis, [R]}) -> ?PI * R * R;
flaeche({rechteck, [A, B]}) -> A * B;
flaeche({dreieck, [A, B, C]}) ->
    S = (A + B + C) / 2,
    wurzel(S * (S - A) * (S - B) * (S - C)).

umfang({kreis, [R]}) -> 2 * ?PI * R;
umfang({rechteck, [A, B]}) -> 2 * (A + B);
umfang({dreieck, [A, B, C]}) -> A + B + C.

ecken({Art, _}) ->
    case Art of
        kreis -> 0;
        rechteck -> 4;
        dreieck -> 3;
        _ -> -1
    end.

%% Quadratwurzel nach Newton
wurzel(V) when V =< 0 -> 0.0;
wurzel(V) -> wurzel(V, V, 0).
wurzel(_, X, N) when N >= ?MAX_SCHRITTE -> X;
wurzel(V, X, N) ->
    Neu = 0.5 * (X + V / X),
    case abs(Neu - X) < ?EPS of
        true -> Neu;
        false -> wurzel(V, Neu, N + 1)
    end.

%% Groesster gemeinsamer Teiler nach Euklid
ggt(A, 0) -> A;
ggt(A, B) -> ggt(B, A rem B).

ist_prim(N) when N < 2 -> false;
ist_prim(N) -> not lists:any(fun(T) -> N rem T =:= 0 end, lists:seq(2, trunc(math:sqrt(N)))).

main(_) ->
    io:format("Formen-Rechner~n"),
    Formen = [{kreis, [2.5]}, {rechteck, [4.0, 3.0]},
              {dreieck, [3.0, 4.0, 5.0]}, {dreieck, [1.0, 2.0, 10.0]}], % TODO: weitere Formen
    Gueltig = lists:filtermap(fun(F) ->
        try pruefe(F) of
            ok -> {true, F}
        catch
            throw:{ungueltig, Text} ->
                io:format("Fehler: ~s~n", [Text]),
                false
        end
    end, Formen),
    Sortiert = lists:sort(fun(A, B) -> flaeche(A) =< flaeche(B) end, Gueltig),
    lists:foreach(fun({Art, _} = F) ->
        Fl = flaeche(F),
        Status = case Fl >= 10.0 of true -> "gross"; false -> "klein" end,
        io:format("~s: Flaeche=~s Umfang=~s ~s Ecken=~B~n",
            [name(Art), fmt(Fl, 2), fmt(umfang(F), 2), Status, ecken(F)])
    end, Sortiert),
    io:format("ggT(48, 18) = ~B~n", [ggt(48, 18)]),
    Primzahlen = [integer_to_list(N) || N <- lists:seq(2, 30), ist_prim(N)],
    io:format("Primzahlen bis 30: ~s~n", [lists:join(" ", Primzahlen)]),
    io:format("Wurzel(2) = ~s~n", [fmt(wurzel(2.0), 8)]),
    io:format("Maske: ~B~n", [16#FF band 2#10101010]),
    io:format("Skala: ~B~n", [1_000_000 div 8]).
