<#
.SYNOPSIS
    Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code).
.DESCRIPTION
    Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24.
    Berechnet Flaeche und Umfang einfacher Formen und etwas Zahlentheorie.
.EXAMPLE
    pwsh -File 14_powershell.ps1
#>
Set-StrictMode -Version Latest
[System.Threading.Thread]::CurrentThread.CurrentCulture = [cultureinfo]::InvariantCulture

$script:Kreiszahl = 3.141592653589793   # Kreiszahl
$script:Eps = 1e-9                      # Abbruchschwelle fuer Newton
$script:MaxSchritte = 50
$script:Maske = 0xFF -band 0b10101010   # Hex- und Binaerliteral (ab PowerShell 7)
$script:Skala = [int](1000000 / 8)

function Get-Wurzel {
    <#
    .SYNOPSIS
        Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
    #>
    param([double]$X)
    if ($X -le 0) { return 0.0 }
    $alt = $X
    for ($i = 0; $i -lt $script:MaxSchritte; $i++) {
        $neu = 0.5 * ($alt + $X / $alt)
        if ([math]::Abs($neu - $alt) -lt $script:Eps) { return $neu }
        $alt = $neu
    }
    return $alt
}

function Get-Ggt {
    # Groesster gemeinsamer Teiler nach Euklid.
    param([int]$A, [int]$B)
    while ($B -ne 0) {
        $rest = $A % $B
        $A = $B
        $B = $rest
    }
    return $A
}

function Test-Prim {
    # Primzahltest durch Probedivision bis zur Wurzel von N.
    param([int]$N)
    if ($N -lt 2) { return $false }
    for ($i = 2; $i * $i -le $N; $i++) {
        if ($N % $i -eq 0) { return $false }
    }
    return $true
}

# Wird geworfen, wenn Masse keine gueltige Form ergeben.
class FormFehler : System.Exception {
    FormFehler([string]$text) : base($text) {}
}

class Form {
    [string] Name() { return $this.GetType().Name }
    [double] Flaeche() { throw 'nicht implementiert' }
    [double] Umfang() { throw 'nicht implementiert' }
}

class Kreis : Form {
    [double]$R
    Kreis([double]$r) {
        if ($r -le 0) { throw [FormFehler]::new(('Kreis {0:F1} ungueltig' -f $r)) }
        $this.R = $r
    }
    [double] Flaeche() { return $script:Kreiszahl * $this.R * $this.R }
    [double] Umfang() { return 2 * $script:Kreiszahl * $this.R }
}

class Rechteck : Form {
    [double]$Breite
    [double]$Hoehe
    Rechteck([double]$breite, [double]$hoehe) {
        if ($breite -le 0 -or $hoehe -le 0) {
            throw [FormFehler]::new(('Rechteck {0:F1}/{1:F1} ungueltig' -f $breite, $hoehe))
        }
        $this.Breite = $breite
        $this.Hoehe = $hoehe
    }
    [double] Flaeche() { return $this.Breite * $this.Hoehe }
    [double] Umfang() { return 2 * ($this.Breite + $this.Hoehe) }
}

class Dreieck : Form {
    [double]$A
    [double]$B
    [double]$C
    Dreieck([double]$a, [double]$b, [double]$c) {
        if ($a + $b -le $c -or $a + $c -le $b -or $b + $c -le $a) {
            throw [FormFehler]::new(('Dreieck {0:F1}/{1:F1}/{2:F1} ungueltig' -f $a, $b, $c))
        }
        $this.A = $a; $this.B = $b; $this.C = $c
    }
    [double] Umfang() { return $this.A + $this.B + $this.C }
    [double] Flaeche() {
        $s = $this.Umfang() / 2   # Satz des Heron
        return Get-Wurzel ($s * ($s - $this.A) * ($s - $this.B) * ($s - $this.C))
    }
}

function Get-Ecken {
    param([Form]$Form)
    switch ($Form.Name()) {
        'Dreieck'  { return 3 }
        'Rechteck' { return 4 }
        'Kreis'    { return 0 }
        default    { return -1 }
    }
}

'Formen-Rechner'
$formen = [System.Collections.Generic.List[Form]]::new()
$formen.Add([Kreis]::new(2.5))
$formen.Add([Rechteck]::new(4.0, 3.0))
$formen.Add([Dreieck]::new(3.0, 4.0, 5.0))
try {
    $formen.Add([Dreieck]::new(1.0, 2.0, 10.0))   # TODO: weitere Formen
}
catch {
    if ($_.Exception.InnerException -is [FormFehler]) {
        'Fehler: ' + $_.Exception.InnerException.Message
    }
    else { throw }
}
foreach ($f in ($formen | Sort-Object { $_.Flaeche() })) {
    $status = if ($f.Flaeche() -ge 10.0) { 'gross' } else { 'klein' }
    '{0}: Flaeche={1:F2} Umfang={2:F2} {3} Ecken={4}' -f $f.Name(), $f.Flaeche(), $f.Umfang(), $status, (Get-Ecken $f)
}
'ggT(48, 18) = {0}' -f (Get-Ggt 48 18)
$prim = 2..30 | Where-Object { Test-Prim $_ }
'Primzahlen bis 30: ' + ($prim -join ' ')
'Wurzel(2) = {0:F8}' -f (Get-Wurzel 2)
"Maske: $script:Maske"
"Skala: $script:Skala"
