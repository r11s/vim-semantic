' ------------------------------------------------------------------
' Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
' Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
' VBScript.  Starten: cscript //nologo 61_vbscript.vbs
' ------------------------------------------------------------------
Option Explicit

Const PI_WERT = 3.141592653589793
Const EPS = 0.000000001
Const MAX_SCHRITTE = 50
Const FORM_FEHLER = 1001          ' eigener Fehlercode statt eigener Ausnahmeklasse

REM Zahl mit n Nachkommastellen als Text (unabhaengig von der Systemsprache)
Function Fmt(x, n)
    Dim skal, wert, ganz, rest
    skal = 10 ^ n
    wert = Int(x * skal + 0.5)
    ganz = wert \ skal
    rest = CStr(wert - ganz * skal)
    Do While Len(rest) < n
        rest = "0" & rest
    Loop
    Fmt = CStr(ganz) & "." & rest
End Function

' Quadratwurzel nach Newton
Function Wurzel(v)
    Dim x, nx, i
    If v <= 0 Then
        Wurzel = 0
        Exit Function
    End If
    x = v
    For i = 1 To MAX_SCHRITTE
        nx = 0.5 * (x + v / x)
        If Abs(nx - x) < EPS Then
            x = nx
            Exit For
        End If
        x = nx
    Next
    Wurzel = x
End Function

Class Kreis
    Public R
    Public Function Flaeche(): Flaeche = PI_WERT * R * R: End Function
    Public Function Umfang(): Umfang = 2 * PI_WERT * R: End Function
    Public Function Ecken(): Ecken = 0: End Function
    Public Function Art(): Art = "Kreis": End Function
End Class

Class Rechteck
    Public A, B
    Public Function Flaeche(): Flaeche = A * B: End Function
    Public Function Umfang(): Umfang = 2 * (A + B): End Function
    Public Function Ecken(): Ecken = 4: End Function
    Public Function Art(): Art = "Rechteck": End Function
End Class

Class Dreieck
    Public A, B, C
    Public Function Flaeche()
        Dim s
        s = (A + B + C) / 2
        Flaeche = Wurzel(s * (s - A) * (s - B) * (s - C))
    End Function
    Public Function Umfang(): Umfang = A + B + C: End Function
    Public Function Ecken(): Ecken = 3: End Function
    Public Function Art(): Art = "Dreieck": End Function
End Class

' Fabrik mit Pruefung: loest bei ungueltigen Massen einen Fehler aus
Function NeuesDreieck(a, b, c)
    If a + b <= c Or a + c <= b Or b + c <= a Then
        Err.Raise FORM_FEHLER, "Formen", "Dreieck " & Fmt(a, 1) & "/" & Fmt(b, 1) & "/" & Fmt(c, 1) & " ungueltig"
    End If
    Dim d
    Set d = New Dreieck
    d.A = a: d.B = b: d.C = c
    Set NeuesDreieck = d
End Function

Function Ggt(a, b)
    Dim r
    Do While b <> 0
        r = a Mod b
        a = b
        b = r
    Loop
    Ggt = a
End Function

Function IstPrim(n)
    Dim t
    IstPrim = False
    If n < 2 Then Exit Function
    t = 2
    Do While t * t <= n
        If n Mod t = 0 Then Exit Function
        t = t + 1
    Loop
    IstPrim = True
End Function

Dim formen(3), anzahl, i, j, k, d, tmp, meldung, liste, status
anzahl = 0
WScript.Echo "Formen-Rechner"

Set k = New Kreis
k.R = 2.5
Set formen(anzahl) = k: anzahl = anzahl + 1

Set k = New Rechteck
k.A = 4.0: k.B = 3.0
Set formen(anzahl) = k: anzahl = anzahl + 1

Dim werte
werte = Array(Array(3.0, 4.0, 5.0), Array(1.0, 2.0, 10.0))   ' TODO: weitere Formen
For i = 0 To UBound(werte)
    On Error Resume Next
    Set d = NeuesDreieck(werte(i)(0), werte(i)(1), werte(i)(2))
    If Err.Number = FORM_FEHLER Then
        meldung = Err.Description
        Err.Clear
        WScript.Echo "Fehler: " & meldung
    ElseIf Err.Number = 0 Then
        Set formen(anzahl) = d: anzahl = anzahl + 1
    End If
    On Error GoTo 0
Next

' Sortieren nach Flaeche (Bubblesort)
For i = 0 To anzahl - 2
    For j = 0 To anzahl - 2 - i
        If formen(j).Flaeche() > formen(j + 1).Flaeche() Then
            Set tmp = formen(j)
            Set formen(j) = formen(j + 1)
            Set formen(j + 1) = tmp
        End If
    Next
Next

For i = 0 To anzahl - 1
    If formen(i).Flaeche() >= 10.0 Then status = "gross" Else status = "klein"
    WScript.Echo formen(i).Art() & ": Flaeche=" & Fmt(formen(i).Flaeche(), 2) & _
        " Umfang=" & Fmt(formen(i).Umfang(), 2) & " " & status & " Ecken=" & formen(i).Ecken()
Next

WScript.Echo "ggT(48, 18) = " & Ggt(48, 18)
liste = ""
For i = 2 To 30
    If IstPrim(i) Then liste = liste & " " & i
Next
WScript.Echo "Primzahlen bis 30:" & liste
WScript.Echo "Wurzel(2) = " & Fmt(Wurzel(2), 8)
WScript.Echo "Maske: " & (&HFF And &HAA)       ' kein Binaerliteral in VBScript
WScript.Echo "Skala: " & (1000000 \ 8)
