% ------------------------------------------------------------------
% Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
% Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
% MATLAB/Octave: Datei als formen.m speichern, dann "formen" aufrufen.
% ------------------------------------------------------------------
function formen()
%FORMEN Berechnet Flaeche und Umfang einfacher Formen, dazu Zahlentheorie.
%   Die Hilfetexte direkt nach der Funktionszeile sind MATLABs Doc-Kommentare.

    formen_liste = [neu_kreis(2.5), neu_rechteck(4.0, 3.0), neu_dreieck(3.0, 4.0, 5.0)];
    disp('Formen-Rechner');
    try
        formen_liste(end + 1) = neu_dreieck(1.0, 2.0, 10.0);   % TODO: weitere Formen
    catch ex
        if strcmp(ex.identifier, 'Formen:ungueltig')
            fprintf('Fehler: %s\n', ex.message);
        else
            rethrow(ex);
        end
    end

    %% Sortieren nach Flaeche
    [~, reihe] = sort(arrayfun(@flaeche, formen_liste));
    for f = formen_liste(reihe)
        if flaeche(f) >= 10.0
            status = 'gross';
        else
            status = 'klein';
        end
        fprintf('%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n', ...
                f.art, flaeche(f), umfang(f), status, ecken(f));
    end

    %{
      Zahlentheorie: ggT, Primzahlen, Wurzel.
      Konstanten stehen in konstanten().
    %}
    k = konstanten();
    fprintf('ggT(48, 18) = %d\n', ggt(48, 18));
    prim = arrayfun(@num2str, find(arrayfun(@ist_prim, 2:30)) + 1, 'UniformOutput', false);
    fprintf('Primzahlen bis 30: %s\n', strjoin(prim, ' '));
    fprintf('Wurzel(2) = %.8f\n', wurzel(2));
    fprintf('Maske: %d\n', k.maske);
    fprintf('Skala: %d\n', k.skala);
end

function k = konstanten()
    k.pi = 3.141592653589793;                % Kreiszahl
    k.eps = 1e-9;                            % Abbruchschwelle fuer Newton
    k.max_schritte = 50;
    k.maske = bitand(0xFF, 0b10101010);      % Hex- und Binaerliteral
    k.skala = floor(1000000 / 8);            % Ganzzahldivision
end

function w = wurzel(x)
%WURZEL Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
    k = konstanten();
    w = 0.0;
    if x <= 0
        return;
    end
    alt = x;
    w = alt;
    for i = 1:k.max_schritte
        neu = 0.5 * (alt + x / alt);
        w = neu;
        if abs(neu - alt) < k.eps
            return;
        end
        alt = neu;
    end
end

function a = ggt(a, b)
%GGT Groesster gemeinsamer Teiler nach Euklid.
    while b ~= 0
        rest = mod(a, b);
        a = b;
        b = rest;
    end
end

function ok = ist_prim(n)
%IST_PRIM Primzahltest durch Probedivision bis zur Wurzel von n.
    ok = false;
    if n < 2
        return;
    end
    i = 2;
    while i * i <= n
        if mod(n, i) == 0
            return;
        end
        i = i + 1;
    end
    ok = true;
end

function f = neu_kreis(r)
    if r <= 0
        error('Formen:ungueltig', 'Kreis %.1f ungueltig', r);
    end
    f = struct('art', 'Kreis', 'a', r, 'b', 0, 'c', 0);
end

function f = neu_rechteck(breite, hoehe)
    if breite <= 0 || hoehe <= 0
        error('Formen:ungueltig', 'Rechteck %.1f/%.1f ungueltig', breite, hoehe);
    end
    f = struct('art', 'Rechteck', 'a', breite, 'b', hoehe, 'c', 0);
end

function f = neu_dreieck(a, b, c)
    if a + b <= c || a + c <= b || b + c <= a
        error('Formen:ungueltig', 'Dreieck %.1f/%.1f/%.1f ungueltig', a, b, c);
    end
    f = struct('art', 'Dreieck', 'a', a, 'b', b, 'c', c);
end

function m = umfang(f)
    switch f.art
        case 'Kreis'
            m = 2 * konstanten().pi * f.a;
        case 'Rechteck'
            m = 2 * (f.a + f.b);
        case 'Dreieck'
            m = f.a + f.b + f.c;
    end
end

function m = flaeche(f)
    switch f.art
        case 'Kreis'
            m = konstanten().pi * f.a ^ 2;
        case 'Rechteck'
            m = f.a * f.b;
        case 'Dreieck'
            s = umfang(f) / 2;               % Satz des Heron
            m = wurzel(s * (s - f.a) * (s - f.b) * (s - f.c));
    end
end

function n = ecken(f)
    switch f.art
        case 'Dreieck'
            n = 3;
        case 'Rechteck'
            n = 4;
        case 'Kreis'
            n = 0;
        otherwise
            n = -1;
    end
end
