Attribute VB_Name = "Formen"
' ------------------------------------------------------------------
' Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
' Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
' VBA (Excel/Word/Access): Modul importieren, Sub Formenrechner starten.
' Ausgabe im Direktfenster (Strg+G).
' ------------------------------------------------------------------
Option Explicit

Private Const PI_WERT As Double = 3.14159265358979
Private Const EPS As Double = 0.000000001
Private Const MAX_SCHRITTE As Long = 50
Private Const FORM_FEHLER As Long = vbObjectError + 1001   ' eigener Fehlercode

Private Enum Art
    Kreis = 0
    Rechteck = 1
    Dreieck = 2
End Enum

''' Eine Form: Art und bis zu drei Masse.
Private Type Form
    Art As Art
    A As Double
    B As Double
    C As Double
End Type

Private Function Fmt(ByVal x As Double, ByVal n As Long) As String
    Fmt = Replace(Format$(x, "0." & String$(n, "0")), ",", ".")
End Function

' Quadratwurzel nach Newton
Private Function Wurzel(ByVal v As Double) As Double
    Dim x As Double, nx As Double, i As Long
    If v <= 0 Then Exit Function
    x = v
    For i = 1 To MAX_SCHRITTE
        nx = 0.5 * (x + v / x)
        If Abs(nx - x) < EPS Then x = nx: Exit For
        x = nx
    Next i
    Wurzel = x
End Function

Private Function FormName(f As Form) As String
    Select Case f.Art
        Case Kreis: FormName = "Kreis"
        Case Rechteck: FormName = "Rechteck"
        Case Else: FormName = "Dreieck"
    End Select
End Function

' Loest bei ungueltigen Massen einen Fehler aus
Private Sub Pruefe(f As Form)
    Dim ok As Boolean, masse As String
    masse = Fmt(f.A, 1)
    Select Case f.Art
        Case Kreis
            ok = f.A > 0
        Case Rechteck
            ok = f.A > 0 And f.B > 0
            masse = masse & "/" & Fmt(f.B, 1)
        Case Dreieck
            ok = (f.A + f.B > f.C) And (f.A + f.C > f.B) And (f.B + f.C > f.A)
            masse = masse & "/" & Fmt(f.B, 1) & "/" & Fmt(f.C, 1)
    End Select
    If Not ok Then Err.Raise FORM_FEHLER, "Formen", FormName(f) & " " & masse & " ungueltig"
End Sub

Private Function Flaeche(f As Form) As Double
    Dim s As Double
    Select Case f.Art
        Case Kreis: Flaeche = PI_WERT * f.A * f.A
        Case Rechteck: Flaeche = f.A * f.B
        Case Dreieck
            s = (f.A + f.B + f.C) / 2
            Flaeche = Wurzel(s * (s - f.A) * (s - f.B) * (s - f.C))
    End Select
End Function

Private Function Umfang(f As Form) As Double
    Select Case f.Art
        Case Kreis: Umfang = 2 * PI_WERT * f.A
        Case Rechteck: Umfang = 2 * (f.A + f.B)
        Case Dreieck: Umfang = f.A + f.B + f.C
    End Select
End Function

Private Function Ecken(f As Form) As Long
    Select Case f.Art
        Case Kreis: Ecken = 0
        Case Rechteck: Ecken = 4
        Case Dreieck: Ecken = 3
        Case Else: Ecken = -1
    End Select
End Function

Private Function Ggt(ByVal a As Long, ByVal b As Long) As Long
    Dim r As Long
    Do While b <> 0
        r = a Mod b: a = b: b = r
    Loop
    Ggt = a
End Function

Private Function IstPrim(ByVal n As Long) As Boolean
    Dim t As Long
    If n < 2 Then Exit Function
    For t = 2 To n
        If t * t > n Then Exit For
        If n Mod t = 0 Then Exit Function
    Next t
    IstPrim = True
End Function

Private Function NeueForm(a As Art, x As Double, y As Double, z As Double) As Form
    NeueForm.Art = a: NeueForm.A = x: NeueForm.B = y: NeueForm.C = z
End Function

Public Sub Formenrechner()
    Dim alle(0 To 3) As Form, gueltig(0 To 3) As Form, tmp As Form
    Dim n As Long, i As Long, j As Long, liste As String, status As String
    Debug.Print "Formen-Rechner"
    alle(0) = NeueForm(Kreis, 2.5, 0, 0)
    alle(1) = NeueForm(Rechteck, 4#, 3#, 0)
    alle(2) = NeueForm(Dreieck, 3#, 4#, 5#)
    alle(3) = NeueForm(Dreieck, 1#, 2#, 10#)   ' TODO: weitere Formen
    For i = 0 To 3
        On Error Resume Next
        Pruefe alle(i)
        If Err.Number = FORM_FEHLER Then
            Debug.Print "Fehler: " & Err.Description
            Err.Clear
        ElseIf Err.Number = 0 Then
            gueltig(n) = alle(i): n = n + 1
        End If
        On Error GoTo 0
    Next i
    ' Sortieren nach Flaeche (Bubblesort)
    For i = 0 To n - 2
        For j = 0 To n - 2 - i
            If Flaeche(gueltig(j)) > Flaeche(gueltig(j + 1)) Then
                tmp = gueltig(j): gueltig(j) = gueltig(j + 1): gueltig(j + 1) = tmp
            End If
        Next j
    Next i
    For i = 0 To n - 1
        status = IIf(Flaeche(gueltig(i)) >= 10#, "gross", "klein")
        Debug.Print FormName(gueltig(i)) & ": Flaeche=" & Fmt(Flaeche(gueltig(i)), 2) & _
            " Umfang=" & Fmt(Umfang(gueltig(i)), 2) & " " & status & " Ecken=" & Ecken(gueltig(i))
    Next i
    Debug.Print "ggT(48, 18) = " & Ggt(48, 18)
    For i = 2 To 30
        If IstPrim(i) Then liste = liste & " " & i
    Next i
    Debug.Print "Primzahlen bis 30:" & liste
    Debug.Print "Wurzel(2) = " & Fmt(Wurzel(2#), 8)
    Debug.Print "Maske: " & (&HFF And &HAA)     ' kein Binaerliteral in VBA
    Debug.Print "Skala: " & (1000000 \ 8)
End Sub
