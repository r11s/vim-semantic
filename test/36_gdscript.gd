## ------------------------------------------------------------------
## Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
## Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
## Starten: godot --headless -s 36_gdscript.gd   (getestet mit Godot 3.5: xvfb-run godot3 -s ...)
## GDScript kennt keine Ausnahmen: Fehler werden als FormFehler-Objekt geliefert.
## ------------------------------------------------------------------
extends SceneTree

const PI_WERT = 3.141592653589793
const EPS = 1e-9
const MAX_SCHRITTE = 50

# Eigener Fehlertyp (Ersatz fuer eine Ausnahme)
class FormFehler:
	var meldung = ""
	func _init(m):
		meldung = m

# Hilfsklasse: Quadratwurzel nach Newton
class Mathe:
	static func wurzel(v):
		if v <= 0:
			return 0.0
		var x = v
		for i in range(MAX_SCHRITTE):
			var nx = 0.5 * (x + v / x)
			if abs(nx - x) < EPS:
				return nx
			x = nx
		return x

# Basisklasse mit der gemeinsamen Schnittstelle
class Form:
	func flaeche():
		return 0.0
	func umfang():
		return 0.0
	func ecken():
		return -1
	func art():
		return "Form"

class Kreis extends Form:
	var r = 0.0
	func _init(radius):
		r = radius
	func flaeche():
		return PI_WERT * r * r
	func umfang():
		return 2 * PI_WERT * r
	func ecken():
		return 0
	func art():
		return "Kreis"

class Rechteck extends Form:
	var a = 0.0
	var b = 0.0
	func _init(x, y):
		a = x
		b = y
	func flaeche():
		return a * b
	func umfang():
		return 2 * (a + b)
	func ecken():
		return 4
	func art():
		return "Rechteck"

class Dreieck extends Form:
	var a = 0.0
	var b = 0.0
	var c = 0.0
	func _init(x, y, z):
		a = x
		b = y
		c = z
	func flaeche():
		var s = (a + b + c) / 2
		return Mathe.wurzel(s * (s - a) * (s - b) * (s - c))
	func umfang():
		return a + b + c
	func ecken():
		return 3
	func art():
		return "Dreieck"

func fmt(x, n):
	return ("%." + str(n) + "f") % x

# Fabrik mit Pruefung: liefert Form oder FormFehler
func baue_dreieck(a, b, c):
	if a + b <= c or a + c <= b or b + c <= a:
		return FormFehler.new("Dreieck %s/%s/%s ungueltig" % [fmt(a, 1), fmt(b, 1), fmt(c, 1)])
	return Dreieck.new(a, b, c)

func ggt(a, b):
	while b != 0:
		var r = a % b
		a = b
		b = r
	return a

func ist_prim(n):
	if n < 2:
		return false
	var t = 2
	while t * t <= n:
		if n % t == 0:
			return false
		t += 1
	return true

func _init():
	print("Formen-Rechner")
	var kandidaten = [
		Kreis.new(2.5),
		Rechteck.new(4.0, 3.0),
		baue_dreieck(3.0, 4.0, 5.0),
		baue_dreieck(1.0, 2.0, 10.0),  # TODO: weitere Formen
	]
	var formen = []
	for k in kandidaten:
		if k is FormFehler:
			print("Fehler: " + k.meldung)
		else:
			formen.append(k)
	# Sortieren nach Flaeche (Einfuegesortierung)
	for i in range(1, formen.size()):
		var f = formen[i]
		var j = i - 1
		while j >= 0 and formen[j].flaeche() > f.flaeche():
			formen[j + 1] = formen[j]
			j -= 1
		formen[j + 1] = f
	for f in formen:
		var status = "gross" if f.flaeche() >= 10.0 else "klein"
		print("%s: Flaeche=%s Umfang=%s %s Ecken=%d" % [f.art(), fmt(f.flaeche(), 2), fmt(f.umfang(), 2), status, f.ecken()])
	print("ggT(48, 18) = %d" % ggt(48, 18))
	var primzahlen = ""
	for n in range(2, 31):
		if ist_prim(n):
			primzahlen += " " + str(n)
	print("Primzahlen bis 30:" + primzahlen)
	print("Wurzel(2) = " + fmt(Mathe.wurzel(2.0), 8))
	print("Maske: %d" % (0xFF & 0b10101010))
	print("Skala: %d" % (1_000_000 / 8))
	quit()
