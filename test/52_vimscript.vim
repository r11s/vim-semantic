" ------------------------------------------------------------------
" Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
" Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
" Starten: vim -es -u NONE -c 'source 52_vimscript.vim' -c 'qa!'
" ------------------------------------------------------------------
vim9script

const PI = 3.141592653589793
const EPS = 1.0e-9
const MAX_SCHRITTE = 50

var ausgabe: list<string> = []

def Ausgeben(text: string)
  add(ausgabe, text)
enddef

# Eine Form ist ein Dict mit art und masse.
def MakeForm(art: string, masse: list<float>): dict<any>
  return {art: art, masse: masse}
enddef

def Zahl(x: float, stellen: number): string
  return printf('%.' .. stellen .. 'f', x)
enddef

def Wurzel(v: float): float
  if v <= 0.0
    return 0.0
  endif
  var x = v
  for i in range(MAX_SCHRITTE)
    const nx = 0.5 * (x + v / x)
    if abs(nx - x) < EPS
      return nx
    endif
    x = nx
  endfor
  return x
enddef

# Wirft eine Ausnahme bei ungueltigen Massen.
def Pruefe(f: dict<any>)
  const m = f.masse
  var ok = true
  if f.art == 'Kreis'
    ok = m[0] > 0.0
  elseif f.art == 'Rechteck'
    ok = m[0] > 0.0 && m[1] > 0.0
  elseif f.art == 'Dreieck'
    ok = m[0] + m[1] > m[2] && m[0] + m[2] > m[1] && m[1] + m[2] > m[0]
  endif
  if !ok
    const texte = mapnew(m, (_, x) => Zahl(x, 1))
    throw 'FORMFEHLER:' .. f.art .. ' ' .. join(texte, '/') .. ' ungueltig'
  endif
enddef

def Flaeche(f: dict<any>): float
  const m = f.masse
  if f.art == 'Kreis'
    return PI * m[0] * m[0]
  elseif f.art == 'Rechteck'
    return m[0] * m[1]
  endif
  const s = (m[0] + m[1] + m[2]) / 2.0
  return Wurzel(s * (s - m[0]) * (s - m[1]) * (s - m[2]))
enddef

def Umfang(f: dict<any>): float
  const m = f.masse
  if f.art == 'Kreis'
    return 2.0 * PI * m[0]
  elseif f.art == 'Rechteck'
    return 2.0 * (m[0] + m[1])
  endif
  return m[0] + m[1] + m[2]
enddef

def Ecken(f: dict<any>): number
  return get({Kreis: 0, Rechteck: 4, Dreieck: 3}, f.art, -1)
enddef

def Ggt(a0: number, b0: number): number
  var a = a0
  var b = b0
  while b != 0
    [a, b] = [b, a % b]
  endwhile
  return a
enddef

def IstPrim(n: number): bool
  if n < 2
    return false
  endif
  var t = 2
  while t * t <= n
    if n % t == 0
      return false
    endif
    t += 1
  endwhile
  return true
enddef

def Haupt()
  Ausgeben('Formen-Rechner')
  const formen = [MakeForm('Kreis', [2.5]), MakeForm('Rechteck', [4.0, 3.0]),
    MakeForm('Dreieck', [3.0, 4.0, 5.0]), MakeForm('Dreieck', [1.0, 2.0, 10.0])] # TODO: mehr
  var gueltig: list<dict<any>> = []
  for f in formen
    try
      Pruefe(f)
      add(gueltig, f)
    catch /^FORMFEHLER:/
      Ausgeben('Fehler: ' .. substitute(v:exception, '^FORMFEHLER:', '', ''))
    endtry
  endfor
  sort(gueltig, (a, b) => Flaeche(a) < Flaeche(b) ? -1 : 1)
  for f in gueltig
    const status = Flaeche(f) >= 10.0 ? 'gross' : 'klein'
    Ausgeben(printf('%s: Flaeche=%s Umfang=%s %s Ecken=%d', f.art,
      Zahl(Flaeche(f), 2), Zahl(Umfang(f), 2), status, Ecken(f)))
  endfor
  Ausgeben('ggT(48, 18) = ' .. Ggt(48, 18))
  const primzahlen = filter(range(2, 30), (_, n) => IstPrim(n))
  Ausgeben('Primzahlen bis 30: ' .. join(primzahlen, ' '))
  Ausgeben('Wurzel(2) = ' .. Zahl(Wurzel(2.0), 8))
  Ausgeben('Maske: ' .. and(0xFF, 0b10101010))
  Ausgeben('Skala: ' .. 1000000 / 8)
enddef

Haupt()
writefile(ausgabe, '/dev/stdout')
