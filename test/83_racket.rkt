#lang racket
(require racket/generic)
;; ------------------------------------------------------------------
;; Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
;; Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
;; Starten: racket 83_racket.rkt
;; ------------------------------------------------------------------
(define PI 3.141592653589793)
(define EPS 1e-9)
(define MAX-SCHRITTE 50)

#| Eigene Ausnahme fuer ungueltige Masse |#
(struct exn:form-fehler exn:fail ())

;; Gemeinsame Schnittstelle: Generics
(define-generics form
  (flaeche form)
  (umfang form)
  (ecken form)
  (art form))

(define (fmt x n)
  (real->decimal-string x n))

;; Quadratwurzel nach Newton
(define (wurzel v)
  (if (<= v 0)
      0.0
      (let loop ([x (exact->inexact v)] [i 0])
        (define nx (* 0.5 (+ x (/ v x))))
        (if (or (< (abs (- nx x)) EPS) (>= i MAX-SCHRITTE))
            nx
            (loop nx (add1 i))))))

(struct kreis (r)
  #:methods gen:form
  [(define (flaeche k) (* PI (kreis-r k) (kreis-r k)))
   (define (umfang k) (* 2 PI (kreis-r k)))
   (define (ecken k) 0)
   (define (art k) "Kreis")])

(struct rechteck (a b)
  #:methods gen:form
  [(define (flaeche r) (* (rechteck-a r) (rechteck-b r)))
   (define (umfang r) (* 2 (+ (rechteck-a r) (rechteck-b r))))
   (define (ecken r) 4)
   (define (art r) "Rechteck")])

(struct dreieck (a b c)
  #:methods gen:form
  [(define (flaeche d)
     (define s (/ (+ (dreieck-a d) (dreieck-b d) (dreieck-c d)) 2))
     (wurzel (* s (- s (dreieck-a d)) (- s (dreieck-b d)) (- s (dreieck-c d)))))
   (define (umfang d) (+ (dreieck-a d) (dreieck-b d) (dreieck-c d)))
   (define (ecken d) 3)
   (define (art d) "Dreieck")])

(define (neues-dreieck a b c)
  (unless (and (> (+ a b) c) (> (+ a c) b) (> (+ b c) a))
    (raise (exn:form-fehler
            (format "Dreieck ~a/~a/~a ungueltig" (fmt a 1) (fmt b 1) (fmt c 1))
            (current-continuation-marks))))
  (dreieck a b c))

(define (ggt a b)
  (if (zero? b) a (ggt b (remainder a b))))

(define (prim? n)
  (and (>= n 2)
       (for/and ([t (in-range 2 (add1 (integer-sqrt n)))])
         (not (zero? (remainder n t))))))

(define (main)
  (displayln "Formen-Rechner")
  (define fabriken
    (list (λ () (kreis 2.5))
          (λ () (rechteck 4.0 3.0))
          (λ () (neues-dreieck 3.0 4.0 5.0))
          (λ () (neues-dreieck 1.0 2.0 10.0))))   ; TODO: weitere Formen
  (define formen
    (for*/list ([bauen (in-list fabriken)]
                [f (in-value (with-handlers ([exn:form-fehler?
                                              (λ (e) (printf "Fehler: ~a\n" (exn-message e)) #f)])
                               (bauen)))]
                #:when f)
      f))
  (for ([f (in-list (sort formen < #:key flaeche))])
    (printf "~a: Flaeche=~a Umfang=~a ~a Ecken=~a\n"
            (art f) (fmt (flaeche f) 2) (fmt (umfang f) 2)
            (if (>= (flaeche f) 10.0) "gross" "klein") (ecken f)))
  (printf "ggT(48, 18) = ~a\n" (ggt 48 18))
  (printf "Primzahlen bis 30: ~a\n" (string-join (map number->string (filter prim? (range 2 31))) " "))
  (printf "Wurzel(2) = ~a\n" (fmt (wurzel 2.0) 8))
  (printf "Maske: ~a\n" (bitwise-and #xFF #b10101010))
  (printf "Skala: ~a\n" (quotient 1000000 8)))

(main)
