* ------------------------------------------------------------------
* Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
* Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
* Stata (do-file).  Starten: stata -b do 76_stata.do   (Ausgabe in 76_stata.log)
* Stata kennt keine Klassen: Formen stehen im Datensatz, Fehler per capture/_rc.
* ------------------------------------------------------------------
version 17
clear all
set more off

/* Konstanten */
global PI_WERT 3.141592653589793
global EPS 1e-9
global MAX_SCHRITTE 50

* Quadratwurzel nach Newton: Ergebnis in r(w)
program define wurzel, rclass
    args v
    local w = 0
    if `v' > 0 {
        local x = `v'
        forvalues i = 1/$MAX_SCHRITTE {
            local nx = 0.5 * (`x' + `v' / `x')
            if abs(`nx' - `x') < $EPS {
                local x = `nx'
                continue, break
            }
            local x = `nx'
        }
        local w = `x'
    }
    return scalar w = `w'
end

* Prueft eine Form; bei ungueltigen Massen Fehlercode 198 mit Meldung in $meldung
program define pruefe
    args art a b c
    local ok = 1
    if "`art'" == "Kreis" local ok = (`a' > 0)
    if "`art'" == "Rechteck" local ok = (`a' > 0 & `b' > 0)
    if "`art'" == "Dreieck" local ok = (`a' + `b' > `c' & `a' + `c' > `b' & `b' + `c' > `a')
    if !`ok' {
        local fa : display %3.1f `a'
        local fb : display %3.1f `b'
        local fc : display %3.1f `c'
        global meldung "`art' `fa'/`fb'/`fc' ungueltig"
        exit 198
    }
end

program define ggt, rclass
    args a b
    while `b' != 0 {
        local r = mod(`a', `b')
        local a = `b'
        local b = `r'
    }
    return scalar g = `a'
end

program define istprim, rclass
    args n
    local p = (`n' >= 2)
    local t = 2
    while `p' & `t' * `t' <= `n' {
        if mod(`n', `t') == 0 local p = 0
        local t = `t' + 1
    }
    return scalar p = `p'
end

display "Formen-Rechner"
set obs 4
generate str8 art = ""
generate double a = .
generate double b = .
generate double c = .
replace art = "Kreis"    in 1
replace a = 2.5           in 1
replace art = "Rechteck" in 2
replace a = 4.0           in 2
replace b = 3.0           in 2
replace art = "Dreieck"  in 3
replace a = 3.0           in 3
replace b = 4.0           in 3
replace c = 5.0           in 3
replace art = "Dreieck"  in 4      // TODO: weitere Formen
replace a = 1.0           in 4
replace b = 2.0           in 4
replace c = 10.0          in 4

generate byte gueltig = 1
generate double flaeche = .
generate double umfang = .
generate byte ecken = .
forvalues i = 1/`=_N' {
    local art = art[`i']
    capture pruefe `art' `=a[`i']' `=b[`i']' `=c[`i']'
    if _rc == 198 {
        display "Fehler: $meldung"
        replace gueltig = 0 in `i'
        continue
    }
    if "`art'" == "Kreis" {
        replace flaeche = $PI_WERT * a^2 in `i'
        replace umfang = 2 * $PI_WERT * a in `i'
        replace ecken = 0 in `i'
    }
    else if "`art'" == "Rechteck" {
        replace flaeche = a * b in `i'
        replace umfang = 2 * (a + b) in `i'
        replace ecken = 4 in `i'
    }
    else {
        local s = (a[`i'] + b[`i'] + c[`i']) / 2
        wurzel `=`s' * (`s' - a[`i']) * (`s' - b[`i']) * (`s' - c[`i'])'
        replace flaeche = r(w) in `i'
        replace umfang = a + b + c in `i'
        replace ecken = 3 in `i'
    }
}
keep if gueltig
sort flaeche
forvalues i = 1/`=_N' {
    local status = cond(flaeche[`i'] >= 10.0, "gross", "klein")
    display art[`i'] ": Flaeche=" %4.2f flaeche[`i'] " Umfang=" %4.2f umfang[`i'] " `status' Ecken=" ecken[`i']
}
ggt 48 18
display "ggT(48, 18) = " r(g)
local liste ""
forvalues n = 2/30 {
    istprim `n'
    if r(p) local liste "`liste' `n'"
}
display "Primzahlen bis 30:`liste'"
wurzel 2
display "Wurzel(2) = " %10.8f r(w)
* Bitweises Und ueber 8 Bit (Stata hat keinen Operator dafuer): 255 AND 170
local x = 255
local y = 170
local maske = 0
local bit = 1
forvalues k = 1/8 {
    if mod(`x', 2) == 1 & mod(`y', 2) == 1 local maske = `maske' + `bit'
    local x = floor(`x' / 2)
    local y = floor(`y' / 2)
    local bit = `bit' * 2
}
display "Maske: `maske'"
display "Skala: " floor(1000000 / 8)
