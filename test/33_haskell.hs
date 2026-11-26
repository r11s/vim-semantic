{-# LANGUAGE BinaryLiterals, NumericUnderscores, ScopedTypeVariables #-}
{- ------------------------------------------------------------------
   Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
   Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
   Start: runghc 33_haskell.hs
   ------------------------------------------------------------------ -}
module Main (main) where

import Control.Exception (Exception, throwIO, try)
import Data.Bits ((.&.))
import Data.List (intercalate, sortOn)
import Text.Printf (printf)

kreiszahl, eps :: Double
kreiszahl = 3.141592653589793   -- Kreiszahl
eps = 1e-9                      -- Abbruchschwelle fuer Newton

maxSchritte :: Int
maxSchritte = 50

maske, skala :: Int
maske = 0xFF .&. 0b10101010     -- Hex- und Binaerliteral
skala = 1_000_000 `div` 8

-- | Wird geworfen, wenn Masse keine gueltige Form ergeben.
newtype FormFehler = FormFehler String deriving Show
instance Exception FormFehler

-- | Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
wurzel :: Double -> Double
wurzel x
  | x <= 0 = 0
  | otherwise = go (0 :: Int) x
  where
    go i alt
      | i >= maxSchritte = alt
      | abs (neu - alt) < eps = neu
      | otherwise = go (i + 1) neu
      where neu = 0.5 * (alt + x / alt)

-- | Groesster gemeinsamer Teiler nach Euklid.
ggt :: Int -> Int -> Int
ggt a 0 = a
ggt a b = ggt b (a `mod` b)

-- | Primzahltest durch Probedivision bis zur Wurzel von n.
istPrim :: Int -> Bool
istPrim n = n >= 2 && all (\i -> n `mod` i /= 0) (takeWhile (\i -> i * i <= n) [2 ..])

-- | Gemeinsame Schnittstelle aller Formen.
class Messbar a where
  flaeche :: a -> Double
  umfang :: a -> Double
  name :: a -> String

data Form = Kreis Double | Rechteck Double Double | Dreieck Double Double Double

instance Messbar Form where
  flaeche (Kreis r) = kreiszahl * r * r
  flaeche (Rechteck b h) = b * h
  flaeche d@(Dreieck a b c) = wurzel (s * (s - a) * (s - b) * (s - c))
    where s = umfang d / 2  -- Satz des Heron
  umfang (Kreis r) = 2 * kreiszahl * r
  umfang (Rechteck b h) = 2 * (b + h)
  umfang (Dreieck a b c) = a + b + c
  name (Kreis _) = "Kreis"
  name (Rechteck _ _) = "Rechteck"
  name (Dreieck {}) = "Dreieck"

pruefe :: Bool -> String -> Form -> IO Form
pruefe ok meldung form = if ok then return form else throwIO (FormFehler meldung)

kreis :: Double -> IO Form
kreis r = pruefe (r > 0) (printf "Kreis %.1f ungueltig" r) (Kreis r)

rechteck :: Double -> Double -> IO Form
rechteck b h = pruefe (b > 0 && h > 0) (printf "Rechteck %.1f/%.1f ungueltig" b h) (Rechteck b h)

dreieck :: Double -> Double -> Double -> IO Form
dreieck a b c =
  pruefe (a + b > c && a + c > b && b + c > a)
         (printf "Dreieck %.1f/%.1f/%.1f ungueltig" a b c) (Dreieck a b c)

ecken :: Form -> Int
ecken f = case name f of
  "Dreieck" -> 3
  "Rechteck" -> 4
  "Kreis" -> 0
  _ -> -1

main :: IO ()
main = do
  putStrLn "Formen-Rechner"
  k <- kreis 2.5
  r <- rechteck 4.0 3.0
  d <- dreieck 3.0 4.0 5.0
  ergebnis <- try (dreieck 1.0 2.0 10.0)   -- TODO: weitere Formen
  extra <- case ergebnis of
    Left (FormFehler meldung) -> putStrLn ("Fehler: " ++ meldung) >> return []
    Right f -> return [f]
  mapM_ zeile (sortOn flaeche ([k, r, d] ++ extra))
  printf "ggT(48, 18) = %d\n" (ggt 48 18)
  putStrLn ("Primzahlen bis 30: " ++ intercalate " " (map show (filter istPrim [2 .. 30])))
  printf "Wurzel(2) = %.8f\n" (wurzel 2)
  printf "Maske: %d\n" maske
  printf "Skala: %d\n" skala
  where
    zeile f = printf "%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d\n"
                (name f) (flaeche f) (umfang f)
                (if flaeche f >= 10.0 then "gross" else "klein" :: String) (ecken f)
