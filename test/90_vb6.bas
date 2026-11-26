Attribute VB_Name = "modFormen"
' ------------------------------------------------------------------
' Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
' Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
' Visual Basic 6: Standardmodul mit Sub Main als Startobjekt.
' Konsolenausgabe ueber die Win32-API (mit /SUBSYSTEM:CONSOLE gelinkt).
' ------------------------------------------------------------------
Option Explicit

Private Declare Function GetStdHandle Lib "kernel32" (ByVal nStdHandle As Long) As Long
Private Declare Function WriteFile Lib "kernel32" (ByVal hFile As Long, ByVal lpBuffer As String, _
    ByVal nNumberOfBytesToWrite As Long, lpNumberOfBytesWritten As Long, ByVal lpOverlapped As Long) As Long

Private Const STD_OUTPUT_HANDLE As Long = -11&
Private Const PI_WERT As Double = 3.14159265358979
Private Const EPS As Double = 0.000000001
Private Const MAX_SCHRITTE As Integer = 50
Private Const FORM_FEHLER As Long = vbObjectError + 1001

Private Const ART_KREIS As Integer = 0
Private Const ART_RECHTECK As Integer = 1
Private Const ART_DREIECK As Integer = 2

'''' Eine Form: Art und bis zu drei Masse.
Private Type TForm
    Art As Integer
    A As Double
    B As Double
    C As Double
End Type

Private Sub Ausgeben(ByVal s As String)
    Dim geschrieben As Long
    s = s & vbCrLf
    WriteFile GetStdHandle(STD_OUTPUT_HANDLE), s, Len(s), geschrieben, 0&
End Sub

Private Function Fmt(ByVal x As Double, ByVal n As Integer) As String
    Dim skal As Double, wert As Double, rest As String
    skal = 10 ^ n
    wert = Int(x * skal + 0.5)
    rest = CStr(wert - Int(wert / skal) * skal)
    Do While Len(rest) < n
        rest = "0" & rest
    Loop
    Fmt = CStr(Int(wert / skal)) & "." & rest
End Function

' Quadratwurzel nach Newton
Private Function Wurzel(ByVal v As Double) As Double
    Dim x As Double, nx As Double, i As Integer
    If v <= 0 Then Exit Function
    x = v
    For i = 1 To MAX_SCHRITTE
        nx = 0.5 * (x + v / x)
        If Abs(nx - x) < EPS Then
            x = nx
            Exit For
        End If
        x = nx
    Next i
    Wurzel = x
End Function

Private Function ArtName(f As TForm) As String
    Select Case f.Art
        Case ART_KREIS: ArtName = "Kreis"
        Case ART_RECHTECK: ArtName = "Rechteck"
        Case Else: ArtName = "Dreieck"
    End Select
End Function

Private Sub Pruefe(f As TForm)
    Dim ok As Boolean, masse As String
    ok = True
    masse = Fmt(f.A, 1)
    Select Case f.Art
        Case ART_KREIS
            ok = (f.A > 0)
        Case ART_RECHTECK
            ok = (f.A > 0) And (f.B > 0)
            masse = masse & "/" & Fmt(f.B, 1)
        Case ART_DREIECK
            ok = (f.A + f.B > f.C) And (f.A + f.C > f.B) And (f.B + f.C > f.A)
            masse = masse & "/" & Fmt(f.B, 1) & "/" & Fmt(f.C, 1)
    End Select
    If Not ok Then Err.Raise FORM_FEHLER, "Formen", ArtName(f) & " " & masse & " ungueltig"
End Sub

Private Function Flaeche(f As TForm) As Double
    Dim s As Double
    Select Case f.Art
        Case ART_KREIS
            Flaeche = PI_WERT * f.A * f.A
        Case ART_RECHTECK
            Flaeche = f.A * f.B
        Case ART_DREIECK
            s = (f.A + f.B + f.C) / 2
            Flaeche = Wurzel(s * (s - f.A) * (s - f.B) * (s - f.C))
    End Select
End Function

Private Function Umfang(f As TForm) As Double
    Select Case f.Art
        Case ART_KREIS: Umfang = 2 * PI_WERT * f.A
        Case ART_RECHTECK: Umfang = 2 * (f.A + f.B)
        Case ART_DREIECK: Umfang = f.A + f.B + f.C
    End Select
End Function

Private Function Ecken(f As TForm) As Integer
    Select Case f.Art
        Case ART_KREIS: Ecken = 0
        Case ART_RECHTECK: Ecken = 4
        Case ART_DREIECK: Ecken = 3
        Case Else: Ecken = -1
    End Select
End Function

Private Function Ggt(ByVal a As Long, ByVal b As Long) As Long
    Dim r As Long
    Do While b <> 0
        r = a Mod b
        a = b
        b = r
    Loop
    Ggt = a
End Function

Private Function IstPrim(ByVal n As Long) As Boolean
    Dim t As Long
    If n < 2 Then Exit Function
    t = 2
    Do While t * t <= n
        If n Mod t = 0 Then Exit Function
        t = t + 1
    Loop
    IstPrim = True
End Function

Private Sub Setze(f As TForm, ByVal a As Integer, ByVal x As Double, ByVal y As Double, ByVal z As Double)
    f.Art = a: f.A = x: f.B = y: f.C = z
End Sub

Public Sub Main()
    Dim alle(0 To 3) As TForm, gueltig(0 To 3) As TForm, tmp As TForm
    Dim n As Integer, i As Integer, j As Integer, liste As String, status As String
    Ausgeben "Formen-Rechner"
    Setze alle(0), ART_KREIS, 2.5, 0, 0
    Setze alle(1), ART_RECHTECK, 4#, 3#, 0
    Setze alle(2), ART_DREIECK, 3#, 4#, 5#
    Setze alle(3), ART_DREIECK, 1#, 2#, 10#     ' TODO: weitere Formen
    For i = 0 To 3
        On Error GoTo Fehler
        Pruefe alle(i)
        gueltig(n) = alle(i)
        n = n + 1
Weiter:
    Next i
    On Error GoTo 0
    ' Sortieren nach Flaeche (Bubblesort)
    For i = 0 To n - 2
        For j = 0 To n - 2 - i
            If Flaeche(gueltig(j)) > Flaeche(gueltig(j + 1)) Then
                tmp = gueltig(j)
                gueltig(j) = gueltig(j + 1)
                gueltig(j + 1) = tmp
            End If
        Next j
    Next i
    For i = 0 To n - 1
        If Flaeche(gueltig(i)) >= 10# Then status = "gross" Else status = "klein"
        Ausgeben ArtName(gueltig(i)) & ": Flaeche=" & Fmt(Flaeche(gueltig(i)), 2) & _
            " Umfang=" & Fmt(Umfang(gueltig(i)), 2) & " " & status & " Ecken=" & Ecken(gueltig(i))
    Next i
    Ausgeben "ggT(48, 18) = " & Ggt(48, 18)
    For i = 2 To 30
        If IstPrim(i) Then liste = liste & " " & i
    Next i
    Ausgeben "Primzahlen bis 30:" & liste
    Ausgeben "Wurzel(2) = " & Fmt(Wurzel(2#), 8)
    Ausgeben "Maske: " & (&HFF And &HAA)           ' kein Binaerliteral in VB6
    Ausgeben "Skala: " & (1000000 \ 8)
    Exit Sub

Fehler:
    If Err.Number = FORM_FEHLER Then Ausgeben "Fehler: " & Err.Description
    Err.Clear
    Resume Weiter
End Sub
