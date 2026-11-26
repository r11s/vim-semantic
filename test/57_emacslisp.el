;;; 57_emacslisp.el --- Formen-Rechner  -*- lexical-binding: t; -*-
;; ------------------------------------------------------------------
;; Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
;; Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
;; Starten: emacs --batch -Q -l 57_emacslisp.el
;; ------------------------------------------------------------------
;;; Code:
(require 'cl-lib)

(defconst formen-pi 3.141592653589793 "Kreiszahl.")
(defconst formen-eps 1.0e-9 "Genauigkeit der Newton-Iteration.")
(defconst formen-max-schritte 50)

(define-error 'formen-fehler "Ungueltige Form")

(cl-defstruct (formen-form (:constructor formen-form (art masse)))
  "Eine Form mit Art (Symbol) und Massen (Liste)."
  art masse)

(defun formen--zahl (x stellen)
  "Formatiert X mit STELLEN Nachkommastellen."
  (format (format "%%.%df" stellen) x))

(defun formen-wurzel (v)
  "Quadratwurzel von V nach Newton."
  (if (<= v 0)
      0.0
    (let ((x (float v)) (fertig nil) (i 0))
      (while (and (not fertig) (< i formen-max-schritte))
        (let ((nx (* 0.5 (+ x (/ v x)))))
          (when (< (abs (- nx x)) formen-eps) (setq fertig t))
          (setq x nx i (1+ i))))
      x)))

(defun formen-name (art)
  (cdr (assq art '((kreis . "Kreis") (rechteck . "Rechteck") (dreieck . "Dreieck")))))

(defun formen-pruefe (f)
  "Signalisiert `formen-fehler' bei ungueltigen Massen von F."
  (let* ((m (formen-form-masse f))
         (ok (pcase (formen-form-art f)
               ('kreis (> (nth 0 m) 0))
               ('rechteck (and (> (nth 0 m) 0) (> (nth 1 m) 0)))
               ('dreieck (cl-destructuring-bind (a b c) m
                           (and (> (+ a b) c) (> (+ a c) b) (> (+ b c) a))))
               (_ t))))
    (unless ok
      (signal 'formen-fehler
              (list (format "%s %s ungueltig" (formen-name (formen-form-art f))
                            (mapconcat (lambda (x) (formen--zahl x 1)) m "/")))))))

(defun formen-flaeche (f)
  (let ((m (formen-form-masse f)))
    (pcase (formen-form-art f)
      ('kreis (* formen-pi (nth 0 m) (nth 0 m)))
      ('rechteck (* (nth 0 m) (nth 1 m)))
      ('dreieck (let ((s (/ (apply #'+ m) 2.0)))
                  (formen-wurzel (* s (- s (nth 0 m)) (- s (nth 1 m)) (- s (nth 2 m)))))))))

(defun formen-umfang (f)
  (let ((m (formen-form-masse f)))
    (pcase (formen-form-art f)
      ('kreis (* 2 formen-pi (nth 0 m)))
      ('rechteck (* 2 (+ (nth 0 m) (nth 1 m))))
      ('dreieck (apply #'+ m)))))

(defun formen-ecken (f)
  (pcase (formen-form-art f) ('kreis 0) ('rechteck 4) ('dreieck 3) (_ -1)))

(defun formen-ggt (a b)
  (while (/= b 0)
    (setq b (prog1 (% a b) (setq a b))))
  a)

(defun formen-prim-p (n)
  (and (>= n 2)
       (cl-loop for tt from 2 while (<= (* tt tt) n)
                never (zerop (% n tt)))))

(defun formen-main ()
  (princ "Formen-Rechner\n")
  (let ((gueltig nil))
    (dolist (f (list (formen-form 'kreis '(2.5)) (formen-form 'rechteck '(4.0 3.0))
                     (formen-form 'dreieck '(3.0 4.0 5.0))
                     (formen-form 'dreieck '(1.0 2.0 10.0)))) ; TODO: weitere Formen
      (condition-case err
          (progn (formen-pruefe f) (push f gueltig))
        (formen-fehler (princ (format "Fehler: %s\n" (cadr err))))))
    (dolist (f (sort (nreverse gueltig)
                     (lambda (a b) (< (formen-flaeche a) (formen-flaeche b)))))
      (princ (format "%s: Flaeche=%s Umfang=%s %s Ecken=%d\n"
                     (formen-name (formen-form-art f))
                     (formen--zahl (formen-flaeche f) 2)
                     (formen--zahl (formen-umfang f) 2)
                     (if (>= (formen-flaeche f) 10.0) "gross" "klein")
                     (formen-ecken f)))))
  (princ (format "ggT(48, 18) = %d\n" (formen-ggt 48 18)))
  (princ (format "Primzahlen bis 30: %s\n"
                 (mapconcat #'number-to-string
                            (seq-filter #'formen-prim-p (number-sequence 2 30)) " ")))
  (princ (format "Wurzel(2) = %s\n" (formen--zahl (formen-wurzel 2.0) 8)))
  (princ (format "Maske: %d\n" (logand #xFF #b10101010)))
  (princ (format "Skala: %d\n" (/ 1000000 8))))

(formen-main)
;;; 57_emacslisp.el ends here
