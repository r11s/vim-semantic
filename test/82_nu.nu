# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
# Nushell.  Starten: nu 82_nu.nu
# Nushell kennt keine Klassen: Formen sind Records, Fehler per `error make`.
# ------------------------------------------------------------------
const PI_WERT = 3.141592653589793
const EPS = 1e-9
const MAX_SCHRITTE = 50

# Zahl mit n Nachkommastellen als Text
def fmt [x: float, n: int]: nothing -> string {
    $x | into string --decimals $n
}

# Quadratwurzel nach Newton
def wurzel [v: float]: nothing -> float {
    if $v <= 0 { return 0.0 }
    mut x = $v
    for _ in 1..$MAX_SCHRITTE {
        let nx = 0.5 * ($x + $v / $x)
        if ($nx - $x | math abs) < $EPS { return $nx }
        $x = $nx
    }
    $x
}

# Neue Form; wirft bei ungueltigen Massen einen Fehler
def neue-form [art: string, masse: list<float>]: nothing -> record {
    let ok = match $art {
        "Kreis" => (($masse | get 0) > 0),
        "Rechteck" => (($masse | get 0) > 0 and ($masse | get 1) > 0),
        "Dreieck" => {
            let a = $masse | get 0
            let b = $masse | get 1
            let c = $masse | get 2
            $a + $b > $c and $a + $c > $b and $b + $c > $a
        },
        _ => true
    }
    if not $ok {
        let texte = $masse | each { |m| fmt $m 1 } | str join "/"
        error make { msg: $"($art) ($texte) ungueltig" }
    }
    { art: $art, masse: $masse }
}

def flaeche [f: record]: nothing -> float {
    let m = $f.masse
    match $f.art {
        "Kreis" => ($PI_WERT * ($m | get 0) * ($m | get 0)),
        "Rechteck" => (($m | get 0) * ($m | get 1)),
        _ => {
            let s = ($m | math sum) / 2
            wurzel ($s * ($s - ($m | get 0)) * ($s - ($m | get 1)) * ($s - ($m | get 2)))
        }
    }
}

def umfang [f: record]: nothing -> float {
    let m = $f.masse
    match $f.art {
        "Kreis" => (2 * $PI_WERT * ($m | get 0)),
        "Rechteck" => (2 * (($m | get 0) + ($m | get 1))),
        _ => ($m | math sum)
    }
}

def ecken [f: record]: nothing -> int {
    match $f.art { "Kreis" => 0, "Rechteck" => 4, "Dreieck" => 3, _ => -1 }
}

def ggt [a: int, b: int]: nothing -> int {
    mut x = $a
    mut y = $b
    while $y != 0 {
        let r = $x mod $y
        $x = $y
        $y = $r
    }
    $x
}

def ist-prim [n: int]: nothing -> bool {
    if $n < 2 { return false }
    mut t = 2
    while $t * $t <= $n {
        if ($n mod $t) == 0 { return false }
        $t += 1
    }
    true
}

print "Formen-Rechner"
let wuensche = [
    ["Kreis", [2.5]],
    ["Rechteck", [4.0, 3.0]],
    ["Dreieck", [3.0, 4.0, 5.0]],
    ["Dreieck", [1.0, 2.0, 10.0]]   # TODO: weitere Formen
]
mut formen = []
for w in $wuensche {
    try {
        $formen = ($formen | append (neue-form ($w | get 0) ($w | get 1)))
    } catch { |e|
        print $"Fehler: ($e.msg)"
    }
}
for f in ($formen | each { |f| $f | insert flaeche (flaeche $f) } | sort-by flaeche) {
    let status = if $f.flaeche >= 10.0 { "gross" } else { "klein" }
    print $"($f.art): Flaeche=(fmt $f.flaeche 2) Umfang=(fmt (umfang $f) 2) ($status) Ecken=(ecken $f)"
}
print $"ggT\(48, 18\) = (ggt 48 18)"
let primzahlen = 2..30 | where { |n| ist-prim $n } | str join " "
print $"Primzahlen bis 30: ($primzahlen)"
print $"Wurzel\(2\) = (fmt (wurzel 2.0) 8)"
print $"Maske: (0xFF | bits and 0b10101010)"
print $"Skala: (1_000_000 // 8)"
