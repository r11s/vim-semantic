#!/usr/bin/env bash
# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
# Start: bash 08_shell.sh
# ------------------------------------------------------------------
set -u

readonly PI=3.141592653589793   # Kreiszahl
readonly EPS=1e-9               # Abbruchschwelle fuer Newton
readonly MAX_SCHRITTE=50
readonly MASKE=$(( 0xFF & 2#10101010 ))   # Hex- und Binaerliteral
readonly SKALA=$(( 1000000 / 8 ))

# Gleitkomma-Rechnung uebernimmt awk: rechne "Ausdruck" "Format"
rechne() {
    awk -v pi="$PI" "BEGIN { printf \"$2\", $1 }"
}

# Quadratwurzel nach Newton: neu = (alt + x / alt) / 2
wurzel() {
    awk -v x="$1" -v eps="$EPS" -v max="$MAX_SCHRITTE" 'BEGIN {
        if (x <= 0) { printf "%.10f", 0; exit }
        alt = x
        for (i = 0; i < max; i++) {
            neu = 0.5 * (alt + x / alt)
            d = neu - alt; if (d < 0) d = -d
            if (d < eps) { printf "%.10f", neu; exit }
            alt = neu
        }
        printf "%.10f", alt
    }'
}

# Groesster gemeinsamer Teiler nach Euklid
ggt() {
    local a=$1 b=$2 rest
    while (( b != 0 )); do
        rest=$(( a % b ))
        a=$b
        b=$rest
    done
    echo "$a"
}

# Primzahltest durch Probedivision bis zur Wurzel von n
ist_prim() {
    local n=$1 i
    (( n < 2 )) && return 1
    for (( i = 2; i * i <= n; i++ )); do
        (( n % i == 0 )) && return 1
    done
    return 0
}

# Eine Form ist ein Eintrag "art:a:b:c" in einem Array
flaeche() {
    local art a b c
    IFS=: read -r art a b c <<< "$1"
    case $art in
        Kreis)    rechne "pi * $a * $a" '%.10f' ;;
        Rechteck) rechne "$a * $b" '%.10f' ;;
        Dreieck)
            local s
            s=$(rechne "($a + $b + $c) / 2" '%.10f')
            wurzel "$(rechne "$s * ($s - $a) * ($s - $b) * ($s - $c)" '%.10f')"
            ;;
    esac
}

umfang() {
    local art a b c
    IFS=: read -r art a b c <<< "$1"
    case $art in
        Kreis)    rechne "2 * pi * $a" '%.10f' ;;
        Rechteck) rechne "2 * ($a + $b)" '%.10f' ;;
        Dreieck)  rechne "$a + $b + $c" '%.10f' ;;
    esac
}

ecken() {
    case ${1%%:*} in
        Dreieck)  echo 3 ;;
        Rechteck) echo 4 ;;
        Kreis)    echo 0 ;;
        *)        echo -1 ;;
    esac
}

# Prueft die Masse; bei Fehler Meldung auf stdout und Rueckgabewert 1
pruefe() {
    local art a b c
    IFS=: read -r art a b c <<< "$1"
    case $art in
        Kreis)
            [[ $(rechne "($a > 0)" '%d') == 1 ]] ||
                { printf 'Kreis %.1f ungueltig\n' "$a"; return 1; } ;;
        Rechteck)
            [[ $(rechne "($a > 0 && $b > 0)" '%d') == 1 ]] ||
                { printf 'Rechteck %.1f/%.1f ungueltig\n' "$a" "$b"; return 1; } ;;
        Dreieck)
            [[ $(rechne "($a + $b > $c && $a + $c > $b && $b + $c > $a)" '%d') == 1 ]] ||
                { printf 'Dreieck %.1f/%.1f/%.1f ungueltig\n' "$a" "$b" "$c"; return 1; } ;;
    esac
}

echo "Formen-Rechner"
kandidaten=("Kreis:2.5" "Rechteck:4.0:3.0" "Dreieck:3.0:4.0:5.0" "Dreieck:1.0:2.0:10.0") # TODO: weitere Formen
formen=()
for k in "${kandidaten[@]}"; do
    if meldung=$(pruefe "$k"); then
        formen+=("$k")
    else
        echo "Fehler: $meldung"
    fi
done

# Sortierung nach Flaeche (aufsteigend)
sortiert=$(for f in "${formen[@]}"; do echo "$(flaeche "$f") $f"; done | sort -n | cut -d' ' -f2)
for f in $sortiert; do
    fl=$(flaeche "$f")
    status=klein
    [[ $(rechne "($fl >= 10.0)" '%d') == 1 ]] && status=gross
    printf '%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n' "${f%%:*}" "$fl" "$(umfang "$f")" "$status" "$(ecken "$f")"
done
echo "ggT(48, 18) = $(ggt 48 18)"
prim=()
for (( n = 2; n <= 30; n++ )); do
    ist_prim "$n" && prim+=("$n")
done
echo "Primzahlen bis 30: ${prim[*]}"
printf 'Wurzel(2) = %.8f\n' "$(wurzel 2)"
echo "Maske: $MASKE"
echo "Skala: $SKALA"
