#!/usr/bin/env tclsh
# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
# Starten: tclsh 49_tcl.tcl
# ------------------------------------------------------------------
set PI 3.141592653589793
set EPS 1e-9
set MAX_SCHRITTE 50

# Eine Form ist ein Dict: art, masse (Liste)
proc form {art args} {
    return [dict create art $art masse $args]
}

# Prueft die Masse; wirft bei Fehler einen Fehler mit Code UNGUELTIG
proc pruefe {f} {
    set m [dict get $f masse]
    set art [dict get $f art]
    set ok 1
    switch -- $art {
        Kreis    { set ok [expr {[lindex $m 0] > 0}] }
        Rechteck { set ok [expr {[lindex $m 0] > 0 && [lindex $m 1] > 0}] }
        Dreieck  {
            lassign $m a b c
            set ok [expr {$a + $b > $c && $a + $c > $b && $b + $c > $a}]
        }
    }
    if {!$ok} {
        set texte {}
        foreach x $m { lappend texte [format %.1f $x] }
        error "$art [join $texte /] ungueltig" "" UNGUELTIG
    }
}

proc wurzel {v} {
    global EPS MAX_SCHRITTE
    if {$v <= 0} { return 0.0 }
    set x [expr {double($v)}]
    for {set i 0} {$i < $MAX_SCHRITTE} {incr i} {
        set nx [expr {0.5 * ($x + $v / $x)}]
        if {abs($nx - $x) < $EPS} { return $nx }
        set x $nx
    }
    return $x
}

proc flaeche {f} {
    global PI
    set m [dict get $f masse]
    switch -- [dict get $f art] {
        Kreis    { return [expr {$PI * [lindex $m 0] ** 2}] }
        Rechteck { return [expr {[lindex $m 0] * [lindex $m 1]}] }
        Dreieck  {
            lassign $m a b c
            set s [expr {($a + $b + $c) / 2.0}]
            return [wurzel [expr {$s * ($s - $a) * ($s - $b) * ($s - $c)}]]
        }
    }
}

proc umfang {f} {
    global PI
    set m [dict get $f masse]
    switch -- [dict get $f art] {
        Kreis    { return [expr {2 * $PI * [lindex $m 0]}] }
        Rechteck { return [expr {2 * ([lindex $m 0] + [lindex $m 1])}] }
        Dreieck  { return [expr [join $m +]] }
    }
}

proc ecken {f} {
    switch -- [dict get $f art] {
        Kreis    { return 0 }
        Rechteck { return 4 }
        Dreieck  { return 3 }
        default  { return -1 }
    }
}

proc ggt {a b} {
    while {$b != 0} { lassign [list $b [expr {$a % $b}]] a b }
    return $a
}

proc ist_prim {n} {
    if {$n < 2} { return 0 }
    for {set t 2} {$t * $t <= $n} {incr t} {
        if {$n % $t == 0} { return 0 }
    }
    return 1
}

puts "Formen-Rechner"
set formen [list [form Kreis 2.5] [form Rechteck 4.0 3.0] \
    [form Dreieck 3.0 4.0 5.0] [form Dreieck 1.0 2.0 10.0]] ;# TODO: weitere Formen
set gueltig {}
foreach f $formen {
    if {[catch {pruefe $f} meldung opts]} {
        puts "Fehler: $meldung"
    } else {
        lappend gueltig [list [flaeche $f] $f]
    }
}
foreach eintrag [lsort -real -index 0 $gueltig] {
    lassign $eintrag fl f
    set status [expr {$fl >= 10.0 ? "gross" : "klein"}]
    puts [format "%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d" \
        [dict get $f art] $fl [umfang $f] $status [ecken $f]]
}
puts "ggT(48, 18) = [ggt 48 18]"
set primzahlen {}
for {set n 2} {$n <= 30} {incr n} { if {[ist_prim $n]} { lappend primzahlen $n } }
puts "Primzahlen bis 30: $primzahlen"
puts [format "Wurzel(2) = %.8f" [wurzel 2.0]]
puts "Maske: [expr {0xFF & 0b10101010}]"
puts "Skala: [expr {1000000 / 8}]"
