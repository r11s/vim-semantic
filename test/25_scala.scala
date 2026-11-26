// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Start: scala-cli run 25_scala.scala   (oder scalac + scala Formen)
// ------------------------------------------------------------------
import java.util.Locale

/** Wird geworfen, wenn Masse keine gueltige Form ergeben. */
class FormFehler(nachricht: String) extends Exception(nachricht)

/** Gemeinsame Schnittstelle aller Formen. */
trait Form {
  def flaeche(): Double
  def umfang(): Double
  def name: String = getClass.getSimpleName
}

class Kreis(r: Double) extends Form {
  if (r <= 0) throw new FormFehler(s"Kreis ${Formen.zahl(r, 1)} ungueltig")
  def flaeche(): Double = Formen.PiWert * r * r
  def umfang(): Double = 2 * Formen.PiWert * r
}

class Rechteck(breite: Double, hoehe: Double) extends Form {
  if (breite <= 0 || hoehe <= 0) {
    throw new FormFehler(s"Rechteck ${Formen.zahl(breite, 1)}/${Formen.zahl(hoehe, 1)} ungueltig")
  }
  def flaeche(): Double = breite * hoehe
  def umfang(): Double = 2 * (breite + hoehe)
}

class Dreieck(a: Double, b: Double, c: Double) extends Form {
  if (a + b <= c || a + c <= b || b + c <= a) {
    throw new FormFehler(s"Dreieck ${Formen.zahl(a, 1)}/${Formen.zahl(b, 1)}/${Formen.zahl(c, 1)} ungueltig")
  }
  def umfang(): Double = a + b + c
  def flaeche(): Double = {
    val s = umfang() / 2 // Satz des Heron
    Formen.wurzel(s * (s - a) * (s - b) * (s - c))
  }
}

object Formen {
  val PiWert = 3.141592653589793 // Kreiszahl
  val Eps = 1e-9                 // Abbruchschwelle fuer Newton
  val MaxSchritte = 50
  val Maske = 0xFF & 0xAA        // Hexliterale; Scala kennt keine Binaerliterale
  val Skala = 1000000 / 8

  def zahl(x: Double, stellen: Int): String = String.format(Locale.ROOT, "%." + stellen + "f", Double.box(x))

  /** Quadratwurzel nach Newton: neu = (alt + x / alt) / 2. */
  def wurzel(x: Double): Double = {
    if (x <= 0) return 0.0
    var alt = x
    var i = 0
    while (i < MaxSchritte) {
      val neu = 0.5 * (alt + x / alt)
      if (math.abs(neu - alt) < Eps) return neu
      alt = neu
      i += 1
    }
    alt
  }

  /** Groesster gemeinsamer Teiler nach Euklid. */
  def ggt(a: Int, b: Int): Int = if (b == 0) a else ggt(b, a % b)

  /** Primzahltest durch Probedivision bis zur Wurzel von n. */
  def istPrim(n: Int): Boolean = n >= 2 && !(2 to n).takeWhile(i => i * i <= n).exists(n % _ == 0)

  def ecken(form: Form): Int = form.name match {
    case "Dreieck"  => 3
    case "Rechteck" => 4
    case "Kreis"    => 0
    case _          => -1
  }

  def main(args: Array[String]): Unit = {
    println("Formen-Rechner")
    var formen = List[Form](new Kreis(2.5), new Rechteck(4.0, 3.0), new Dreieck(3.0, 4.0, 5.0))
    try {
      formen = formen :+ new Dreieck(1.0, 2.0, 10.0) // TODO: weitere Formen
    } catch {
      case fehler: FormFehler => println(s"Fehler: ${fehler.getMessage}")
    }
    for (f <- formen.sortBy(_.flaeche())) {
      val status = if (f.flaeche() >= 10.0) "gross" else "klein"
      println(s"${f.name}: Flaeche=${zahl(f.flaeche(), 2)} Umfang=${zahl(f.umfang(), 2)} $status Ecken=${ecken(f)}")
    }
    println(s"ggT(48, 18) = ${ggt(48, 18)}")
    println("Primzahlen bis 30: " + (2 to 30).filter(istPrim).mkString(" "))
    println(s"Wurzel(2) = ${zahl(wurzel(2), 8)}")
    println(s"Maske: $Maske")
    println(s"Skala: $Skala")
  }
}
