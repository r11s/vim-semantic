"------------------------------------------------------------------
 Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
 Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
 GNU Smalltalk (3.2).  Starten: gst 72_smalltalk.st
------------------------------------------------------------------"

Smalltalk at: #PiWert put: 3.141592653589793e0.
Smalltalk at: #Eps put: 1.0e-9.
Smalltalk at: #MaxSchritte put: 50.

"Eigene Ausnahme fuer ungueltige Masse"
Error subclass: FormFehler [
]

Object subclass: Rechner [
    "Zahl mit n Nachkommastellen als Text"
    Rechner class >> fmt: x stellen: n [
        | skal wert rest |
        skal := 10 raisedTo: n.
        wert := (x * skal + 0.5e0) floor.
        rest := (wert \\ skal) printString: 10.
        [rest size < n] whileTrue: [rest := '0', rest].
        ^(wert // skal) printString, '.', rest
    ]

    "Quadratwurzel nach Newton"
    Rechner class >> wurzel: v [
        | x nx |
        v <= 0 ifTrue: [^0.0e0].
        x := v asFloatD.
        MaxSchritte timesRepeat: [
            nx := 0.5e0 * (x + (v / x)).
            (nx - x) abs < Eps ifTrue: [^nx].
            x := nx].
        ^x
    ]

    Rechner class >> ggt: a mit: b [
        | x y r |
        x := a. y := b.
        [y ~= 0] whileTrue: [r := x \\ y. x := y. y := r].
        ^x
    ]

    Rechner class >> istPrim: n [
        | t |
        n < 2 ifTrue: [^false].
        t := 2.
        [t * t <= n] whileTrue: [
            (n \\ t) = 0 ifTrue: [^false].
            t := t + 1].
        ^true
    ]
]

Object subclass: Form [
    flaeche [ ^self subclassResponsibility ]
    umfang  [ ^self subclassResponsibility ]
    ecken   [ ^-1 ]
    art     [ ^'Form' ]
]

Form subclass: Kreis [
    | r |
    Kreis class >> radius: x [ ^self new setR: x ]
    setR: x [ r := x ]
    flaeche [ ^PiWert * r * r ]
    umfang [ ^2 * PiWert * r ]
    ecken [ ^0 ]
    art [ ^'Kreis' ]
]

Form subclass: Rechteck [
    | a b |
    Rechteck class >> a: x b: y [ ^self new setA: x b: y ]
    setA: x b: y [ a := x. b := y ]
    flaeche [ ^a * b ]
    umfang [ ^2 * (a + b) ]
    ecken [ ^4 ]
    art [ ^'Rechteck' ]
]

Form subclass: Dreieck [
    | a b c |
    Dreieck class >> a: x b: y c: z [
        (x + y <= z or: [x + z <= y or: [y + z <= x]]) ifTrue: [
            ^FormFehler new signal: 'Dreieck ', (Rechner fmt: x stellen: 1), '/',
                (Rechner fmt: y stellen: 1), '/', (Rechner fmt: z stellen: 1), ' ungueltig'].
        ^self new setA: x b: y c: z
    ]
    setA: x b: y c: z [ a := x. b := y. c := z ]
    flaeche [
        | s |
        s := (a + b + c) / 2.
        ^Rechner wurzel: s * (s - a) * (s - b) * (s - c)
    ]
    umfang [ ^a + b + c ]
    ecken [ ^3 ]
    art [ ^'Dreieck' ]
]

Eval [
    | formen liste |
    Transcript showCr: 'Formen-Rechner'.
    formen := OrderedCollection new.
    formen add: (Kreis radius: 2.5e0); add: (Rechteck a: 4.0e0 b: 3.0e0).
    #(#(3.0 4.0 5.0) #(1.0 2.0 10.0)) do: [:w |     "TODO: weitere Formen"
        [formen add: (Dreieck a: (w at: 1) b: (w at: 2) c: (w at: 3))]
            on: FormFehler
            do: [:e | Transcript showCr: 'Fehler: ', e messageText. e return: nil]].
    (formen asSortedCollection: [:x :y | x flaeche <= y flaeche]) do: [:f |
        Transcript showCr: f art, ': Flaeche=', (Rechner fmt: f flaeche stellen: 2),
            ' Umfang=', (Rechner fmt: f umfang stellen: 2), ' ',
            (f flaeche >= 10.0e0 ifTrue: ['gross'] ifFalse: ['klein']),
            ' Ecken=', f ecken printString].
    Transcript showCr: 'ggT(48, 18) = ', (Rechner ggt: 48 mit: 18) printString.
    liste := WriteStream on: String new.
    2 to: 30 do: [:n | (Rechner istPrim: n) ifTrue: [liste nextPut: $ ; nextPutAll: n printString]].
    Transcript showCr: 'Primzahlen bis 30:', liste contents.
    Transcript showCr: 'Wurzel(2) = ', (Rechner fmt: (Rechner wurzel: 2) stellen: 8).
    Transcript showCr: 'Maske: ', (16rFF bitAnd: 2r10101010) printString.
    Transcript showCr: 'Skala: ', (1000000 // 8) printString
]
