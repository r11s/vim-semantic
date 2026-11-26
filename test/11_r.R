#!/usr/bin/env Rscript
# ------------------------------------------------------------------
# Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
# Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
# ------------------------------------------------------------------

PI_WERT <- 3.141592653589793   # Kreiszahl
EPS <- 1e-9                    # Abbruchschwelle fuer Newton
MAX_SCHRITTE <- 50L
MASKE <- bitwAnd(0xFFL, 0xAAL) # Hexliterale; R kennt keine Binaerliterale
SKALA <- 1000000L %/% 8L       # Ganzzahldivision

#' Fehlerobjekt fuer ungueltige Masse
#'
#' @param text Meldung, die spaeter ausgegeben wird
#' @return Eine Condition der Klasse "formFehler"
form_fehler <- function(text) {
  structure(class = c("formFehler", "error", "condition"),
            list(message = text, call = NULL))
}

#' Quadratwurzel nach Newton: neu = (alt + x / alt) / 2
#'
#' @param x Radikand
#' @return Naeherung der Wurzel
wurzel <- function(x) {
  if (x <= 0) return(0)
  alt <- x
  for (i in seq_len(MAX_SCHRITTE)) {
    neu <- 0.5 * (alt + x / alt)
    if (abs(neu - alt) < EPS) return(neu)
    alt <- neu
  }
  alt
}

#' Groesster gemeinsamer Teiler nach Euklid
ggt <- function(a, b) {
  while (b != 0) {
    rest <- a %% b
    a <- b
    b <- rest
  }
  a
}

#' Primzahltest durch Probedivision bis zur Wurzel von n
ist_prim <- function(n) {
  if (n < 2) return(FALSE)
  i <- 2L
  while (i * i <= n) {
    if (n %% i == 0) return(FALSE)
    i <- i + 1L
  }
  TRUE
}

# --- Klassen (S4) ---------------------------------------------------
setClass("Form", representation("VIRTUAL"))
setClass("Kreis", contains = "Form", representation(r = "numeric"))
setClass("Rechteck", contains = "Form", representation(breite = "numeric", hoehe = "numeric"))
setClass("Dreieck", contains = "Form", representation(a = "numeric", b = "numeric", c = "numeric"))

invisible(setGeneric("flaeche", function(f) standardGeneric("flaeche")))
invisible(setGeneric("umfang", function(f) standardGeneric("umfang")))

setMethod("flaeche", "Kreis", function(f) PI_WERT * f@r^2)
setMethod("umfang", "Kreis", function(f) 2 * PI_WERT * f@r)
setMethod("flaeche", "Rechteck", function(f) f@breite * f@hoehe)
setMethod("umfang", "Rechteck", function(f) 2 * (f@breite + f@hoehe))
setMethod("umfang", "Dreieck", function(f) f@a + f@b + f@c)
setMethod("flaeche", "Dreieck", function(f) {
  s <- umfang(f) / 2  # Satz des Heron
  wurzel(s * (s - f@a) * (s - f@b) * (s - f@c))
})

kreis <- function(r) {
  if (r <= 0) stop(form_fehler(sprintf("Kreis %.1f ungueltig", r)))
  new("Kreis", r = r)
}

rechteck <- function(breite, hoehe) {
  if (breite <= 0 || hoehe <= 0) {
    stop(form_fehler(sprintf("Rechteck %.1f/%.1f ungueltig", breite, hoehe)))
  }
  new("Rechteck", breite = breite, hoehe = hoehe)
}

dreieck <- function(a, b, c) {
  if (a + b <= c || a + c <= b || b + c <= a) {
    stop(form_fehler(sprintf("Dreieck %.1f/%.1f/%.1f ungueltig", a, b, c)))
  }
  new("Dreieck", a = a, b = b, c = c)
}

name <- function(f) as.character(class(f))

ecken <- function(f) {
  switch(name(f), Dreieck = 3L, Rechteck = 4L, Kreis = 0L, -1L)
}

# --- Hauptprogramm --------------------------------------------------
cat("Formen-Rechner\n")
formen <- list(kreis(2.5), rechteck(4.0, 3.0), dreieck(3.0, 4.0, 5.0))
tryCatch({
  formen[[length(formen) + 1]] <- dreieck(1.0, 2.0, 10.0)  # TODO: weitere Formen
}, formFehler = function(e) {
  cat(sprintf("Fehler: %s\n", conditionMessage(e)))
})
formen <- formen[order(vapply(formen, flaeche, numeric(1)))]
for (f in formen) {
  status <- if (flaeche(f) >= 10.0) "gross" else "klein"
  cat(sprintf("%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n",
              name(f), flaeche(f), umfang(f), status, ecken(f)))
}
cat(sprintf("ggT(48, 18) = %d\n", ggt(48L, 18L)))
prim <- Filter(ist_prim, 2:30)
cat(sprintf("Primzahlen bis 30: %s\n", paste(prim, collapse = " ")))
cat(sprintf("Wurzel(2) = %.8f\n", wurzel(2)))
cat(sprintf("Maske: %d\n", MASKE))
cat(sprintf("Skala: %d\n", SKALA))
