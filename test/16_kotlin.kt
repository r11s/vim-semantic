// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Uebersetzen: kotlinc 16_kotlin.kt -include-runtime -d formen.jar
// ------------------------------------------------------------------
import java.util.Locale
import kotlin.math.abs

const val PI_WERT = 3.141592653589793      // Kreiszahl
const val EPS = 1e-9                       // Abbruchschwelle fuer Newton
const val MAX_SCHRITTE = 50
const val MASKE = 0xFF and 0b10101010      // Hex- und Binaerliteral
const val SKALA = 1_000_000 / 8

/** Wird geworfen, wenn Masse keine gueltige Form ergeben. */
class FormFehler(nachricht: String) : Exception(nachricht)

/** Formatiert [x] mit [stellen] Nachkommastellen (immer mit Punkt). */
fun fmt(x: Double, stellen: Int): String = String.format(Locale.ROOT, "%.${stellen}f", x)

/**
 * Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
 * @param x Radikand
 * @return Naeherung der Wurzel
 */
fun wurzel(x: Double): Double {
    if (x <= 0) return 0.0
    var alt = x
    repeat(MAX_SCHRITTE) {
        val neu = 0.5 * (alt + x / alt)
        if (abs(neu - alt) < EPS) return neu
        alt = neu
    }
    return alt
}

/** Groesster gemeinsamer Teiler nach Euklid. */
fun ggt(a0: Int, b0: Int): Int {
    var a = a0
    var b = b0
    while (b != 0) {
        val rest = a % b
        a = b
        b = rest
    }
    return a
}

/** Primzahltest durch Probedivision bis zur Wurzel von [n]. */
fun istPrim(n: Int): Boolean {
    if (n < 2) return false
    var i = 2
    while (i * i <= n) {
        if (n % i == 0) return false
        i++
    }
    return true
}

/** Gemeinsame Schnittstelle aller Formen. */
interface Form {
    val name: String get() = javaClass.simpleName
    fun flaeche(): Double
    fun umfang(): Double
}

class Kreis(private val r: Double) : Form {
    init {
        if (r <= 0) throw FormFehler("Kreis ${fmt(r, 1)} ungueltig")
    }

    override fun flaeche() = PI_WERT * r * r
    override fun umfang() = 2 * PI_WERT * r
}

class Rechteck(private val breite: Double, private val hoehe: Double) : Form {
    init {
        if (breite <= 0 || hoehe <= 0) {
            throw FormFehler("Rechteck ${fmt(breite, 1)}/${fmt(hoehe, 1)} ungueltig")
        }
    }

    override fun flaeche() = breite * hoehe
    override fun umfang() = 2 * (breite + hoehe)
}

class Dreieck(private val a: Double, private val b: Double, private val c: Double) : Form {
    init {
        if (a + b <= c || a + c <= b || b + c <= a) {
            throw FormFehler("Dreieck ${fmt(a, 1)}/${fmt(b, 1)}/${fmt(c, 1)} ungueltig")
        }
    }

    override fun umfang() = a + b + c

    override fun flaeche(): Double {
        val s = umfang() / 2 // Satz des Heron
        return wurzel(s * (s - a) * (s - b) * (s - c))
    }
}

fun ecken(form: Form): Int = when (form.name) {
    "Dreieck" -> 3
    "Rechteck" -> 4
    "Kreis" -> 0
    else -> -1
}

fun main() {
    println("Formen-Rechner")
    val formen = mutableListOf<Form>(Kreis(2.5), Rechteck(4.0, 3.0), Dreieck(3.0, 4.0, 5.0))
    try {
        formen.add(Dreieck(1.0, 2.0, 10.0)) // TODO: weitere Formen
    } catch (fehler: FormFehler) {
        println("Fehler: ${fehler.message}")
    }
    for (f in formen.sortedBy { it.flaeche() }) {
        val status = if (f.flaeche() >= 10.0) "gross" else "klein"
        println("${f.name}: Flaeche=${fmt(f.flaeche(), 2)} Umfang=${fmt(f.umfang(), 2)} $status Ecken=${ecken(f)}")
    }
    println("ggT(48, 18) = ${ggt(48, 18)}")
    println("Primzahlen bis 30: " + (2..30).filter { istPrim(it) }.joinToString(" "))
    println("Wurzel(2) = ${fmt(wurzel(2.0), 8)}")
    println("Maske: $MASKE")
    println("Skala: $SKALA")
}
