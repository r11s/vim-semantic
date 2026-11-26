' ------------------------------------------------------------------
' Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
' Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
' ------------------------------------------------------------------
Option Strict On
Option Explicit On

Imports System
Imports System.Collections.Generic
Imports System.Globalization

''' <summary>Wird geworfen, wenn Masse keine gueltige Form ergeben.</summary>
Public Class FormFehler
    Inherits Exception

    Public Sub New(nachricht As String)
        MyBase.New(nachricht)
    End Sub
End Class

''' <summary>Gemeinsame Schnittstelle aller Formen.</summary>
Public Interface IForm
    Function Flaeche() As Double
    Function Umfang() As Double
    ReadOnly Property Name As String
End Interface

Public MustInherit Class Basis
    Implements IForm

    Public MustOverride Function Flaeche() As Double Implements IForm.Flaeche
    Public MustOverride Function Umfang() As Double Implements IForm.Umfang

    Public ReadOnly Property Name As String Implements IForm.Name
        Get
            Return Me.GetType().Name
        End Get
    End Property
End Class

Public Class Kreis
    Inherits Basis

    Private ReadOnly _r As Double

    Public Sub New(r As Double)
        If r <= 0 Then Throw New FormFehler(String.Format("Kreis {0:F1} ungueltig", r))
        _r = r
    End Sub

    Public Overrides Function Flaeche() As Double
        Return Rechner.PI * _r * _r
    End Function

    Public Overrides Function Umfang() As Double
        Return 2 * Rechner.PI * _r
    End Function
End Class

Public Class Rechteck
    Inherits Basis

    Private ReadOnly _breite, _hoehe As Double

    Public Sub New(breite As Double, hoehe As Double)
        If breite <= 0 OrElse hoehe <= 0 Then
            Throw New FormFehler(String.Format("Rechteck {0:F1}/{1:F1} ungueltig", breite, hoehe))
        End If
        _breite = breite
        _hoehe = hoehe
    End Sub

    Public Overrides Function Flaeche() As Double
        Return _breite * _hoehe
    End Function

    Public Overrides Function Umfang() As Double
        Return 2 * (_breite + _hoehe)
    End Function
End Class

Public Class Dreieck
    Inherits Basis

    Private ReadOnly _a, _b, _c As Double

    Public Sub New(a As Double, b As Double, c As Double)
        If a + b <= c OrElse a + c <= b OrElse b + c <= a Then
            Throw New FormFehler(String.Format("Dreieck {0:F1}/{1:F1}/{2:F1} ungueltig", a, b, c))
        End If
        _a = a
        _b = b
        _c = c
    End Sub

    Public Overrides Function Umfang() As Double
        Return _a + _b + _c
    End Function

    Public Overrides Function Flaeche() As Double
        Dim s As Double = Umfang() / 2 ' Satz des Heron
        Return Rechner.Wurzel(s * (s - _a) * (s - _b) * (s - _c))
    End Function
End Class

Public Module Rechner
    Public Const PI As Double = 3.141592653589793 ' Kreiszahl
    Public Const EPS As Double = 1.0E-9           ' Abbruchschwelle fuer Newton
    Public Const MaxSchritte As Integer = 50
    Public Const Maske As Integer = &HFF And &B10101010 ' Hex- und Binaerliteral
    Public Const Skala As Integer = 1000000 \ 8   ' Ganzzahldivision

    ''' <summary>Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.</summary>
    Public Function Wurzel(x As Double) As Double
        If x <= 0 Then Return 0.0
        Dim alt As Double = x
        For i As Integer = 1 To MaxSchritte
            Dim neu As Double = 0.5 * (alt + x / alt)
            If Math.Abs(neu - alt) < EPS Then Return neu
            alt = neu
        Next
        Return alt
    End Function

    ''' <summary>Groesster gemeinsamer Teiler nach Euklid.</summary>
    Public Function Ggt(a As Integer, b As Integer) As Integer
        Do While b <> 0
            Dim rest As Integer = a Mod b
            a = b
            b = rest
        Loop
        Return a
    End Function

    ''' <summary>Primzahltest durch Probedivision bis zur Wurzel von n.</summary>
    Public Function IstPrim(n As Integer) As Boolean
        If n < 2 Then Return False
        Dim i As Integer = 2
        Do While i * i <= n
            If n Mod i = 0 Then Return False
            i += 1
        Loop
        Return True
    End Function

    Public Function Ecken(form As IForm) As Integer
        Select Case form.Name
            Case "Dreieck"
                Return 3
            Case "Rechteck"
                Return 4
            Case "Kreis"
                Return 0
            Case Else
                Return -1
        End Select
    End Function
End Module

Public Module Programm
    Public Sub Main()
        CultureInfo.CurrentCulture = CultureInfo.InvariantCulture
        Console.WriteLine("Formen-Rechner")
        Dim formen As New List(Of IForm) From {New Kreis(2.5), New Rechteck(4.0, 3.0), New Dreieck(3.0, 4.0, 5.0)}
        Try
            formen.Add(New Dreieck(1.0, 2.0, 10.0)) ' TODO: weitere Formen
        Catch fehler As FormFehler
            Console.WriteLine("Fehler: " & fehler.Message)
        End Try
        formen.Sort(Function(x, y) x.Flaeche().CompareTo(y.Flaeche()))
        For Each f As IForm In formen
            Dim status As String = If(f.Flaeche() >= 10.0, "gross", "klein")
            Console.WriteLine("{0}: Flaeche={1:F2} Umfang={2:F2} {3} Ecken={4}",
                              f.Name, f.Flaeche(), f.Umfang(), status, Rechner.Ecken(f))
        Next
        Console.WriteLine("ggT(48, 18) = " & Rechner.Ggt(48, 18))
        Dim prim As New List(Of String)
        For n As Integer = 2 To 30
            If Rechner.IstPrim(n) Then prim.Add(n.ToString())
        Next
        Console.WriteLine("Primzahlen bis 30: " & String.Join(" ", prim))
        Console.WriteLine("Wurzel(2) = {0:F8}", Rechner.Wurzel(2))
        Console.WriteLine("Maske: " & Rechner.Maske)
        Console.WriteLine("Skala: " & Rechner.Skala)
    End Sub
End Module
