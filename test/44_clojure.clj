;; ------------------------------------------------------------------
;; Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
;; Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
;; Starten: clojure 44_clojure.clj
;; ------------------------------------------------------------------
(ns formen)

(def ^:const PI 3.141592653589793)
(def ^:const EPS 1e-9)
(def ^:const MAX-SCHRITTE 50)

(defprotocol Form
  "Gemeinsame Schnittstelle aller Formen."
  (flaeche [this])
  (umfang [this])
  (ecken [this])
  (art [this]))

(defn fmt [x n] (format (str "%." n "f") (double x)))

(defn wurzel
  "Quadratwurzel nach Newton."
  [v]
  (if (<= v 0)
    0.0
    (loop [x (double v), i 0]
      (let [nx (* 0.5 (+ x (/ v x)))]
        (if (or (< (Math/abs (- nx x)) EPS) (>= i MAX-SCHRITTE))
          nx
          (recur nx (inc i)))))))

(defrecord Kreis [r]
  Form
  (flaeche [_] (* PI r r))
  (umfang [_] (* 2 PI r))
  (ecken [_] 0)
  (art [_] "Kreis"))

(defrecord Rechteck [a b]
  Form
  (flaeche [_] (* a b))
  (umfang [_] (* 2 (+ a b)))
  (ecken [_] 4)
  (art [_] "Rechteck"))

(defrecord Dreieck [a b c]
  Form
  (flaeche [_]
    (let [s (/ (+ a b c) 2)]
      (wurzel (* s (- s a) (- s b) (- s c)))))
  (umfang [_] (+ a b c))
  (ecken [_] 3)
  (art [_] "Dreieck"))

(defn dreieck
  "Fabrik mit Pruefung; wirft eine ExceptionInfo bei ungueltigen Massen."
  [a b c]
  (if (and (> (+ a b) c) (> (+ a c) b) (> (+ b c) a))
    (->Dreieck a b c)
    (throw (ex-info (str "Dreieck " (fmt a 1) "/" (fmt b 1) "/" (fmt c 1) " ungueltig")
                    {:art :dreieck}))))

(defn ggt [a b] (if (zero? b) a (recur b (rem a b))))

(defn prim? [n]
  (and (>= n 2)
       (not-any? #(zero? (rem n %)) (range 2 (inc (long (Math/sqrt n)))))))

(defn status [f] (if (>= (flaeche f) 10.0) "gross" "klein")) ; TODO: weitere Formen

(defn -main []
  (println "Formen-Rechner")
  (let [fabriken [#(->Kreis 2.5) #(->Rechteck 4.0 3.0)
                  #(dreieck 3.0 4.0 5.0) #(dreieck 1.0 2.0 10.0)]
        formen (keep (fn [bauen]
                       (try (bauen)
                            (catch clojure.lang.ExceptionInfo e
                              (println (str "Fehler: " (ex-message e)))
                              nil)))
                     fabriken)]
    (doseq [f (sort-by flaeche formen)]
      (println (str (art f) ": Flaeche=" (fmt (flaeche f) 2)
                    " Umfang=" (fmt (umfang f) 2) " " (status f)
                    " Ecken=" (ecken f))))
    (println (str "ggT(48, 18) = " (ggt 48 18)))
    (println (str "Primzahlen bis 30: " (apply str (interpose " " (filter prim? (range 2 31))))))
    (println (str "Wurzel(2) = " (fmt (wurzel 2.0) 8)))
    (println (str "Maske: " (bit-and 0xFF 2r10101010)))
    (println (str "Skala: " (quot 1000000 8)))))

(-main)
