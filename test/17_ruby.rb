#!/usr/bin/env ruby
# frozen_string_literal: true

# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
# ------------------------------------------------------------------

PI_WERT = 3.141592653589793 # Kreiszahl
EPS = 1e-9                  # Abbruchschwelle fuer Newton
MAX_SCHRITTE = 50
MASKE = 0xFF & 0b10101010   # Hex- und Binaerliteral
SKALA = 1_000_000 / 8

# Wird geworfen, wenn Masse keine gueltige Form ergeben.
class FormFehler < StandardError; end

# Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
def wurzel(x)
  return 0.0 if x <= 0

  alt = x
  MAX_SCHRITTE.times do
    neu = 0.5 * (alt + x / alt)
    return neu if (neu - alt).abs < EPS

    alt = neu
  end
  alt
end

# Groesster gemeinsamer Teiler nach Euklid.
def ggt(a, b)
  a, b = b, a % b while b != 0
  a
end

# Primzahltest durch Probedivision bis zur Wurzel von n.
def prim?(n)
  return false if n < 2

  i = 2
  while i * i <= n
    return false if (n % i).zero?

    i += 1
  end
  true
end

# Gemeinsame Basis aller Formen.
class Form
  def name = self.class.name

  def flaeche = raise(NotImplementedError, "#{self.class} muss flaeche liefern")

  def umfang = raise(NotImplementedError, "#{self.class} muss umfang liefern")
end

class Kreis < Form
  def initialize(radius)
    super()
    raise FormFehler, format('Kreis %.1f ungueltig', radius) if radius <= 0

    @radius = radius
  end

  def flaeche = PI_WERT * @radius**2

  def umfang = 2 * PI_WERT * @radius
end

class Rechteck < Form
  def initialize(breite, hoehe)
    super()
    raise FormFehler, format('Rechteck %.1f/%.1f ungueltig', breite, hoehe) if breite <= 0 || hoehe <= 0

    @breite = breite
    @hoehe = hoehe
  end

  def flaeche = @breite * @hoehe

  def umfang = 2 * (@breite + @hoehe)
end

class Dreieck < Form
  def initialize(a, b, c)
    super()
    if a + b <= c || a + c <= b || b + c <= a
      raise FormFehler, format('Dreieck %.1f/%.1f/%.1f ungueltig', a, b, c)
    end

    @a = a
    @b = b
    @c = c
  end

  def umfang = @a + @b + @c

  def flaeche
    s = umfang / 2 # Satz des Heron
    wurzel(s * (s - @a) * (s - @b) * (s - @c))
  end
end

def ecken(form)
  case form.name
  when 'Dreieck' then 3
  when 'Rechteck' then 4
  when 'Kreis' then 0
  else -1
  end
end

puts 'Formen-Rechner'
formen = [Kreis.new(2.5), Rechteck.new(4.0, 3.0), Dreieck.new(3.0, 4.0, 5.0)]
begin
  formen << Dreieck.new(1.0, 2.0, 10.0) # TODO: weitere Formen
rescue FormFehler => e
  puts "Fehler: #{e.message}"
end
formen.sort_by!(&:flaeche)
formen.each do |f|
  status = f.flaeche >= 10.0 ? 'gross' : 'klein'
  puts format('%<n>s: Flaeche=%<fl>.2f Umfang=%<u>.2f %<s>s Ecken=%<e>d',
              n: f.name, fl: f.flaeche, u: f.umfang, s: status, e: ecken(f))
end
puts "ggT(48, 18) = #{ggt(48, 18)}"
prim = (2..30).select { |n| prim?(n) }
puts "Primzahlen bis 30: #{prim.join(' ')}"
puts format('Wurzel(2) = %.8f', wurzel(2.0))
puts "Maske: #{MASKE}"
puts "Skala: #{SKALA}"
