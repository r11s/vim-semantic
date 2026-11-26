# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
# Start: julia 29_julia.jl
# ------------------------------------------------------------------
using Printf

const KREISZAHL = 3.141592653589793      # Kreiszahl
const EPS = 1e-9                         # Abbruchschwelle fuer Newton
const MAX_SCHRITTE = 50
const MASKE = Int(0xFF & 0b10101010)     # Hex- und Binaerliteral
const SKALA = div(1_000_000, 8)         # Ganzzahldivision

#=
Julia arbeitet mit Mehrfachdispatch: die Funktionen flaeche und umfang
haben je eine Methode pro Formtyp, Klassen im engeren Sinn gibt es nicht.
=#

"Wird geworfen, wenn Masse keine gueltige Form ergeben."
struct FormFehler <: Exception
    text::String
end

Base.showerror(io::IO, e::FormFehler) = print(io, e.text)

"""
    wurzel(x)

Quadratwurzel nach Newton: `neu = (alt + x / alt) / 2`.
"""
function wurzel(x::Real)
    x <= 0 && return 0.0
    alt = float(x)
    for _ in 1:MAX_SCHRITTE
        neu = 0.5 * (alt + x / alt)
        abs(neu - alt) < EPS && return neu
        alt = neu
    end
    return alt
end

"Groesster gemeinsamer Teiler nach Euklid."
function ggt(a::Integer, b::Integer)
    while b != 0
        a, b = b, a % b
    end
    return a
end

"Primzahltest durch Probedivision bis zur Wurzel von `n`."
function ist_prim(n::Integer)
    n < 2 && return false
    i = 2
    while i * i <= n
        n % i == 0 && return false
        i += 1
    end
    return true
end

"Gemeinsamer Obertyp aller Formen."
abstract type Form end

struct Kreis <: Form
    r::Float64
    function Kreis(r)
        r <= 0 && throw(FormFehler(@sprintf("Kreis %.1f ungueltig", r)))
        new(r)
    end
end

struct Rechteck <: Form
    breite::Float64
    hoehe::Float64
    function Rechteck(breite, hoehe)
        if breite <= 0 || hoehe <= 0
            throw(FormFehler(@sprintf("Rechteck %.1f/%.1f ungueltig", breite, hoehe)))
        end
        new(breite, hoehe)
    end
end

struct Dreieck <: Form
    a::Float64
    b::Float64
    c::Float64
    function Dreieck(a, b, c)
        if a + b <= c || a + c <= b || b + c <= a
            throw(FormFehler(@sprintf("Dreieck %.1f/%.1f/%.1f ungueltig", a, b, c)))
        end
        new(a, b, c)
    end
end

flaeche(k::Kreis) = KREISZAHL * k.r^2
umfang(k::Kreis) = 2 * KREISZAHL * k.r
flaeche(r::Rechteck) = r.breite * r.hoehe
umfang(r::Rechteck) = 2 * (r.breite + r.hoehe)
umfang(d::Dreieck) = d.a + d.b + d.c

function flaeche(d::Dreieck)
    s = umfang(d) / 2  # Satz des Heron
    return wurzel(s * (s - d.a) * (s - d.b) * (s - d.c))
end

name(f::Form) = string(typeof(f))

function ecken(f::Form)
    n = name(f)
    if n == "Dreieck"
        return 3
    elseif n == "Rechteck"
        return 4
    elseif n == "Kreis"
        return 0
    end
    return -1
end

function main()
    println("Formen-Rechner")
    formen = Form[Kreis(2.5), Rechteck(4.0, 3.0), Dreieck(3.0, 4.0, 5.0)]
    try
        push!(formen, Dreieck(1.0, 2.0, 10.0))  # TODO: weitere Formen
    catch fehler
        fehler isa FormFehler || rethrow()
        println("Fehler: ", fehler.text)
    end
    sort!(formen, by = flaeche)
    for f in formen
        status = flaeche(f) >= 10.0 ? "gross" : "klein"
        @printf("%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n",
                name(f), flaeche(f), umfang(f), status, ecken(f))
    end
    println("ggT(48, 18) = ", ggt(48, 18))
    println("Primzahlen bis 30: ", join(filter(ist_prim, 2:30), " "))
    @printf("Wurzel(2) = %.8f\n", wurzel(2))
    println("Maske: ", MASKE)
    println("Skala: ", SKALA)
end

main()
