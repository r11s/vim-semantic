#!/usr/bin/env lua5.4
-- ------------------------------------------------------------------
-- Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
-- Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
-- ------------------------------------------------------------------

local PI = 3.141592653589793      -- Kreiszahl
local EPS = 1e-9                  -- Abbruchschwelle fuer Newton
local MAX_SCHRITTE = 50
local MASKE = 0xFF & 0xAA         -- Lua kennt Hex-, aber keine Binaerliterale
local SKALA = 1000000 // 8        -- Ganzzahldivision

--[[
  Fehlerobjekt: wird mit error() geworfen und von pcall() gefangen,
  wenn Masse keine gueltige Form ergeben.
]]
local FormFehler = {}
FormFehler.__index = FormFehler
FormFehler.__tostring = function(e) return e.text end

local function neuer_fehler(text)
  return setmetatable({ text = text }, FormFehler)
end

--- Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
-- @param x Radikand
-- @return Naeherung der Wurzel
local function wurzel(x)
  if x <= 0 then return 0.0 end
  local alt = x
  for _ = 1, MAX_SCHRITTE do
    local neu = 0.5 * (alt + x / alt)
    if math.abs(neu - alt) < EPS then return neu end
    alt = neu
  end
  return alt
end

--- Groesster gemeinsamer Teiler nach Euklid.
local function ggt(a, b)
  while b ~= 0 do
    a, b = b, a % b
  end
  return a
end

--- Primzahltest durch Probedivision bis zur Wurzel von n.
local function ist_prim(n)
  if n < 2 then return false end
  local i = 2
  while i * i <= n do
    if n % i == 0 then return false end
    i = i + 1
  end
  return true
end

--- Gemeinsame Basis aller Formen.
local Form = {}
Form.__index = Form

function Form.new(name)
  return setmetatable({ bezeichnung = name }, Form)
end

function Form:name() return self.bezeichnung end
function Form:flaeche() error("nicht implementiert") end
function Form:umfang() error("nicht implementiert") end

local Kreis = setmetatable({}, { __index = Form })
Kreis.__index = Kreis

function Kreis.new(r)
  if r <= 0 then
    error(neuer_fehler(string.format("Kreis %.1f ungueltig", r)))
  end
  local self = setmetatable(Form.new("Kreis"), Kreis)
  self.r = r
  return self
end

function Kreis:flaeche() return PI * self.r ^ 2 end
function Kreis:umfang() return 2 * PI * self.r end

local Rechteck = setmetatable({}, { __index = Form })
Rechteck.__index = Rechteck

function Rechteck.new(breite, hoehe)
  if breite <= 0 or hoehe <= 0 then
    error(neuer_fehler(string.format("Rechteck %.1f/%.1f ungueltig", breite, hoehe)))
  end
  local self = setmetatable(Form.new("Rechteck"), Rechteck)
  self.breite, self.hoehe = breite, hoehe
  return self
end

function Rechteck:flaeche() return self.breite * self.hoehe end
function Rechteck:umfang() return 2 * (self.breite + self.hoehe) end

local Dreieck = setmetatable({}, { __index = Form })
Dreieck.__index = Dreieck

function Dreieck.new(a, b, c)
  if a + b <= c or a + c <= b or b + c <= a then
    error(neuer_fehler(string.format("Dreieck %.1f/%.1f/%.1f ungueltig", a, b, c)))
  end
  local self = setmetatable(Form.new("Dreieck"), Dreieck)
  self.a, self.b, self.c = a, b, c
  return self
end

function Dreieck:umfang() return self.a + self.b + self.c end

function Dreieck:flaeche()
  local s = self:umfang() / 2 -- Satz des Heron
  return wurzel(s * (s - self.a) * (s - self.b) * (s - self.c))
end

local function ecken(form)
  local n = form:name()
  if n == "Dreieck" then
    return 3
  elseif n == "Rechteck" then
    return 4
  elseif n == "Kreis" then
    return 0
  end
  return -1
end

print("Formen-Rechner")
local formen = { Kreis.new(2.5), Rechteck.new(4.0, 3.0), Dreieck.new(3.0, 4.0, 5.0) }
local ok, fehler = pcall(function()
  formen[#formen + 1] = Dreieck.new(1.0, 2.0, 10.0) -- TODO: weitere Formen
end)
if not ok then
  if getmetatable(fehler) ~= FormFehler then error(fehler, 0) end
  print("Fehler: " .. tostring(fehler))
end
table.sort(formen, function(x, y) return x:flaeche() < y:flaeche() end)
for _, f in ipairs(formen) do
  local status = f:flaeche() >= 10.0 and "gross" or "klein"
  print(string.format("%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d",
    f:name(), f:flaeche(), f:umfang(), status, ecken(f)))
end
print("ggT(48, 18) = " .. ggt(48, 18))
local prim = {}
for n = 2, 30 do
  if ist_prim(n) then prim[#prim + 1] = n end
end
print("Primzahlen bis 30: " .. table.concat(prim, " "))
print(string.format("Wurzel(2) = %.8f", wurzel(2)))
print("Maske: " .. MASKE)
print("Skala: " .. SKALA)
