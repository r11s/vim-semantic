#!/usr/bin/sbcl --script
;;; ------------------------------------------------------------------
;;; Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
;;; Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
;;; Common Lisp.   Start: sbcl --script 34_lisp.lisp
;;; ------------------------------------------------------------------

(defconstant +pi-wert+ 3.141592653589793d0)   ; Kreiszahl
(defconstant +eps+ 1d-9)                      ; Abbruchschwelle fuer Newton
(defconstant +max-schritte+ 50)
(defconstant +maske+ (logand #xFF #b10101010)) ; Hex- und Binaerliteral
(defconstant +skala+ (floor 1000000 8))

#|
  Bedingungen (conditions) sind Lisps Ausnahmen: define-condition,
  error zum Ausloesen, handler-case zum Fangen.
|#
(define-condition form-fehler (error)
  ((text :initarg :text :reader fehler-text))
  (:report (lambda (c s) (write-string (fehler-text c) s))))

(defun wurzel (x)
  "Quadratwurzel nach Newton: neu = (alt + x / alt) / 2."
  (if (<= x 0)
      0d0
      (let ((alt x))
        (dotimes (i +max-schritte+ alt)
          (let ((neu (* 0.5d0 (+ alt (/ x alt)))))
            (when (< (abs (- neu alt)) +eps+) (return neu))
            (setf alt neu))))))

(defun ggt (a b)
  "Groesster gemeinsamer Teiler nach Euklid."
  (loop until (zerop b)
        do (psetf a b b (mod a b)))
  a)

(defun prim-p (n)
  "Primzahltest durch Probedivision bis zur Wurzel von N."
  (and (>= n 2)
       (loop for i from 2 while (<= (* i i) n)
             never (zerop (mod n i)))))

;;; Gemeinsame Basis aller Formen (CLOS)
(defclass form () ())
(defgeneric flaeche (f))
(defgeneric umfang (f))
(defgeneric name (f))

(defclass kreis (form) ((r :initarg :r :reader r)))
(defclass rechteck (form) ((breite :initarg :breite :reader breite)
                           (hoehe :initarg :hoehe :reader hoehe)))
(defclass dreieck (form) ((a :initarg :a :reader a) (b :initarg :b :reader b) (c :initarg :c :reader c)))

(defmethod name ((f kreis)) "Kreis")
(defmethod name ((f rechteck)) "Rechteck")
(defmethod name ((f dreieck)) "Dreieck")
(defmethod flaeche ((f kreis)) (* +pi-wert+ (r f) (r f)))
(defmethod umfang ((f kreis)) (* 2 +pi-wert+ (r f)))
(defmethod flaeche ((f rechteck)) (* (breite f) (hoehe f)))
(defmethod umfang ((f rechteck)) (* 2 (+ (breite f) (hoehe f))))
(defmethod umfang ((f dreieck)) (+ (a f) (b f) (c f)))
(defmethod flaeche ((f dreieck))
  (let ((s (/ (umfang f) 2)))                 ; Satz des Heron
    (wurzel (* s (- s (a f)) (- s (b f)) (- s (c f))))))

(defun fehler (fmt &rest args)
  (error 'form-fehler :text (apply #'format nil fmt args)))

(defun neuer-kreis (r)
  (when (<= r 0) (fehler "Kreis ~,1f ungueltig" r))
  (make-instance 'kreis :r r))

(defun neues-rechteck (b h)
  (when (or (<= b 0) (<= h 0)) (fehler "Rechteck ~,1f/~,1f ungueltig" b h))
  (make-instance 'rechteck :breite b :hoehe h))

(defun neues-dreieck (a b c)
  (when (or (<= (+ a b) c) (<= (+ a c) b) (<= (+ b c) a))
    (fehler "Dreieck ~,1f/~,1f/~,1f ungueltig" a b c))
  (make-instance 'dreieck :a a :b b :c c))

(defun ecken (f)
  (case (class-name (class-of f))
    (dreieck 3)
    (rechteck 4)
    (kreis 0)
    (t -1)))

(defun main ()
  (format t "Formen-Rechner~%")
  (let ((formen (list (neuer-kreis 2.5d0) (neues-rechteck 4d0 3d0) (neues-dreieck 3d0 4d0 5d0))))
    (handler-case
        (push (neues-dreieck 1d0 2d0 10d0) formen)   ; TODO: weitere Formen
      (form-fehler (e) (format t "Fehler: ~a~%" e)))
    (dolist (f (sort (copy-list formen) #'< :key #'flaeche))
      (format t "~a: Flaeche=~,2f Umfang=~,2f ~a Ecken=~d~%"
              (name f) (flaeche f) (umfang f)
              (if (>= (flaeche f) 10d0) "gross" "klein") (ecken f))))
  (format t "ggT(48, 18) = ~d~%" (ggt 48 18))
  (format t "Primzahlen bis 30: ~{~d~^ ~}~%" (loop for n from 2 to 30 when (prim-p n) collect n))
  (format t "Wurzel(2) = ~,8f~%" (wurzel 2d0))
  (format t "Maske: ~d~%" +maske+)
  (format t "Skala: ~d~%" +skala+))

(main)
