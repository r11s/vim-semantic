{ ------------------------------------------------------------------
  Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
  Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
  Delphi-Dialekt; getestet mit: fpc -Mdelphi 28_delphi.pas
  ------------------------------------------------------------------ }
program Formen;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$APPTYPE CONSOLE}

uses
  SysUtils, Classes;

const
  PI_WERT = 3.141592653589793;   // Kreiszahl
  EPS = 1e-9;                    // Abbruchschwelle fuer Newton
  MAX_SCHRITTE = 50;
  MASKE = $FF and $AA;          (* Hexliterale; $AA = 10101010 binaer *)
  SKALA = 1000000 div 8;

type
  /// Wird ausgeloest, wenn Masse keine gueltige Form ergeben.
  EFormFehler = class(Exception);

  TArt = (aKreis, aRechteck, aDreieck);

  /// Gemeinsame Basis aller Formen.
  TFigur = class
  public
    function Art: TArt; virtual; abstract;
    function Flaeche: Double; virtual; abstract;
    function Umfang: Double; virtual; abstract;
    function Name: string;
  end;

  TKreis = class(TFigur)
  private
    FRadius: Double;
  public
    constructor Create(R: Double);
    function Art: TArt; override;
    function Flaeche: Double; override;
    function Umfang: Double; override;
  end;

  TRechteck = class(TFigur)
  private
    FBreite, FHoehe: Double;
  public
    constructor Create(Breite, Hoehe: Double);
    function Art: TArt; override;
    function Flaeche: Double; override;
    function Umfang: Double; override;
  end;

  TDreieck = class(TFigur)
  private
    FA, FB, FC: Double;
  public
    constructor Create(A, B, C: Double);
    function Art: TArt; override;
    function Flaeche: Double; override;
    function Umfang: Double; override;
  end;

/// Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
function Wurzel(X: Double): Double;
var
  Alt, Neu: Double;
  I: Integer;
begin
  Result := 0.0;
  if X <= 0 then Exit;
  Alt := X;
  for I := 1 to MAX_SCHRITTE do
  begin
    Neu := 0.5 * (Alt + X / Alt);
    if Abs(Neu - Alt) < EPS then
    begin
      Result := Neu;
      Exit;
    end;
    Alt := Neu;
  end;
  Result := Alt;
end;

/// Groesster gemeinsamer Teiler nach Euklid.
function Ggt(A, B: Integer): Integer;
var
  Rest: Integer;
begin
  while B <> 0 do
  begin
    Rest := A mod B;
    A := B;
    B := Rest;
  end;
  Result := A;
end;

/// Primzahltest durch Probedivision bis zur Wurzel von N.
function IstPrim(N: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if N < 2 then Exit;
  I := 2;
  while I * I <= N do
  begin
    if N mod I = 0 then Exit;
    Inc(I);
  end;
  Result := True;
end;

function TFigur.Name: string;
begin
  Result := Copy(ClassName, 2, Length(ClassName));  // "TKreis" -> "Kreis"
end;

constructor TKreis.Create(R: Double);
begin
  inherited Create;
  if R <= 0 then raise EFormFehler.CreateFmt('Kreis %.1f ungueltig', [R]);
  FRadius := R;
end;

function TKreis.Art: TArt; begin Result := aKreis; end;
function TKreis.Flaeche: Double; begin Result := PI_WERT * FRadius * FRadius; end;
function TKreis.Umfang: Double; begin Result := 2 * PI_WERT * FRadius; end;

constructor TRechteck.Create(Breite, Hoehe: Double);
begin
  inherited Create;
  if (Breite <= 0) or (Hoehe <= 0) then
    raise EFormFehler.CreateFmt('Rechteck %.1f/%.1f ungueltig', [Breite, Hoehe]);
  FBreite := Breite;
  FHoehe := Hoehe;
end;

function TRechteck.Art: TArt; begin Result := aRechteck; end;
function TRechteck.Flaeche: Double; begin Result := FBreite * FHoehe; end;
function TRechteck.Umfang: Double; begin Result := 2 * (FBreite + FHoehe); end;

constructor TDreieck.Create(A, B, C: Double);
begin
  inherited Create;
  if (A + B <= C) or (A + C <= B) or (B + C <= A) then
    raise EFormFehler.CreateFmt('Dreieck %.1f/%.1f/%.1f ungueltig', [A, B, C]);
  FA := A;
  FB := B;
  FC := C;
end;

function TDreieck.Art: TArt; begin Result := aDreieck; end;
function TDreieck.Umfang: Double; begin Result := FA + FB + FC; end;

function TDreieck.Flaeche: Double;
var
  S: Double;
begin
  S := Umfang / 2;  // Satz des Heron
  Result := Wurzel(S * (S - FA) * (S - FB) * (S - FC));
end;

function Ecken(F: TFigur): Integer;
begin
  case F.Art of
    aDreieck:  Result := 3;
    aRechteck: Result := 4;
    aKreis:    Result := 0;
  else
    Result := -1;
  end;
end;

function Vergleich(A, B: Pointer): Integer;
begin
  if TFigur(A).Flaeche < TFigur(B).Flaeche then
    Result := -1
  else if TFigur(A).Flaeche > TFigur(B).Flaeche then
    Result := 1
  else
    Result := 0;
end;

var
  Liste: TList;
  F: TFigur;
  Status, Prim: string;
  I: Integer;
begin
  FormatSettings.DecimalSeparator := '.';
  WriteLn('Formen-Rechner');
  Liste := TList.Create;
  try
    Liste.Add(TKreis.Create(2.5));
    Liste.Add(TRechteck.Create(4.0, 3.0));
    Liste.Add(TDreieck.Create(3.0, 4.0, 5.0));
    try
      Liste.Add(TDreieck.Create(1.0, 2.0, 10.0));  // TODO: weitere Formen
    except
      on E: EFormFehler do WriteLn('Fehler: ', E.Message);
    end;
    Liste.Sort(Vergleich);
    for I := 0 to Liste.Count - 1 do
    begin
      F := TFigur(Liste[I]);
      if F.Flaeche >= 10.0 then Status := 'gross' else Status := 'klein';
      WriteLn(Format('%s: Flaeche=%.2f Umfang=%.2f %s Ecken=%d',
        [F.Name, F.Flaeche, F.Umfang, Status, Ecken(F)]));
    end;
    WriteLn('ggT(48, 18) = ', Ggt(48, 18));
    Prim := '';
    for I := 2 to 30 do
      if IstPrim(I) then Prim := Prim + ' ' + IntToStr(I);
    WriteLn('Primzahlen bis 30:', Prim);
    WriteLn(Format('Wurzel(2) = %.8f', [Wurzel(2)]));
    WriteLn('Maske: ', MASKE);
    WriteLn('Skala: ', SKALA);
  finally
    for I := 0 to Liste.Count - 1 do TObject(Liste[I]).Free;
    Liste.Free;
  end;
end.
