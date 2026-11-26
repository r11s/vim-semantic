;;; ------------------------------------------------------------------
;;; Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
;;; Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
;;; Guile Scheme.  Starten: guile --no-auto-compile 64_scheme.scm
;;; ------------------------------------------------------------------
(use-modules (ice-9 format) (srfi srfi-1) (srfi srfi-9) (srfi srfi-34) (srfi srfi-35))

(define pi-wert 3.141592653589793)
(define eps 1e-9)
(define max-schritte 50)

#| Eine Form besteht aus Art und Massen. |#
(define-record-type <form>
  (make-form art masse)
  form?
  (art form-art)
  (masse form-masse))

(define-condition-type &form-fehler &error form-fehler?
  (meldung form-fehler-meldung))

(define (zahl x n) (format #f "~,vf" n x))

;; Quadratwurzel nach Newton
(define (wurzel v)
  (if (<= v 0)
      0.0
      (let schleife ((x v) (i 0))
        (let ((nx (* 0.5 (+ x (/ v x)))))
          (if (or (< (abs (- nx x)) eps) (>= i max-schritte))
              nx
              (schleife nx (+ i 1)))))))

(define (name art)
  (case art ((kreis) "Kreis") ((rechteck) "Rechteck") ((dreieck) "Dreieck")))

(define (pruefe f)
  (let* ((m (form-masse f))
         (ok (case (form-art f)
               ((kreis) (> (car m) 0))
               ((rechteck) (and (> (car m) 0) (> (cadr m) 0)))
               ((dreieck) (let ((a (car m)) (b (cadr m)) (c (caddr m)))
                            (and (> (+ a b) c) (> (+ a c) b) (> (+ b c) a))))
               (else #t))))
    (unless ok
      (raise (condition (&form-fehler
        (meldung (format #f "~a ~a ungueltig" (name (form-art f))
                         (string-join (map (lambda (x) (zahl x 1)) m) "/")))))))))

(define (flaeche f)
  (let ((m (form-masse f)))
    (case (form-art f)
      ((kreis) (* pi-wert (car m) (car m)))
      ((rechteck) (* (car m) (cadr m)))
      (else (let ((s (/ (apply + m) 2)))
              (wurzel (* s (- s (car m)) (- s (cadr m)) (- s (caddr m)))))))))

(define (umfang f)
  (let ((m (form-masse f)))
    (case (form-art f)
      ((kreis) (* 2 pi-wert (car m)))
      ((rechteck) (* 2 (+ (car m) (cadr m))))
      (else (apply + m)))))

(define (ecken f)
  (case (form-art f) ((kreis) 0) ((rechteck) 4) ((dreieck) 3) (else -1)))

(define (ggt a b) (if (= b 0) a (ggt b (remainder a b))))

(define (prim? n)
  (and (>= n 2)
       (let schleife ((t 2))
         (cond ((> (* t t) n) #t)
               ((= (remainder n t) 0) #f)
               (else (schleife (+ t 1)))))))

(define formen
  (list (make-form 'kreis '(2.5)) (make-form 'rechteck '(4.0 3.0))
        (make-form 'dreieck '(3.0 4.0 5.0))
        (make-form 'dreieck '(1.0 2.0 10.0))))   ; TODO: weitere Formen

(display "Formen-Rechner\n")
(define gueltig
  (filter (lambda (f)
            (guard (e ((form-fehler? e)
                       (format #t "Fehler: ~a~%" (form-fehler-meldung e))
                       #f))
              (pruefe f)
              #t))
          formen))
(for-each
 (lambda (f)
   (format #t "~a: Flaeche=~a Umfang=~a ~a Ecken=~d~%" (name (form-art f))
           (zahl (flaeche f) 2) (zahl (umfang f) 2)
           (if (>= (flaeche f) 10.0) "gross" "klein") (ecken f)))
 (sort gueltig (lambda (a b) (< (flaeche a) (flaeche b)))))
(format #t "ggT(48, 18) = ~d~%" (ggt 48 18))
(format #t "Primzahlen bis 30: ~a~%"
        (string-join (map number->string (filter prim? (iota 29 2))) " "))
(format #t "Wurzel(2) = ~a~%" (zahl (wurzel 2.0) 8))
(format #t "Maske: ~d~%" (logand #xFF #b10101010))
(format #t "Skala: ~d~%" (quotient 1000000 8))
