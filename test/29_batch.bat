@echo off
rem ------------------------------------------------------------------
rem Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
rem Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
rem Windows cmd.exe, nur Ganzzahlen (set /a kennt keine Kommazahlen).
rem Start: 29_batch.bat
rem ------------------------------------------------------------------
setlocal EnableDelayedExpansion

:: Konstanten (Hex-Literal erlaubt, Binaerliteral nicht)
set /a MAX_SCHRITTE=50
set /a "MASKE=0xFF & 0xAA"
set /a "SKALA=1000000 / 8"
set /a RADIKAND=2 * 1000000
set /a BREITE=4, HOEHE=3, SEITE_A=3, SEITE_B=4, SEITE_C=5

echo Formen-Rechner (Batch, nur ganze Zahlen)

rem TODO: weitere Formen
call :dreieck_ok 1 2 10
if errorlevel 1 echo Fehler: Dreieck 1/2/10 ungueltig

rem Form 1: Rechteck, Form 2: Dreieck (Satz des Heron)
set N1=Rechteck
set /a F1=BREITE * HOEHE, U1=2 * (BREITE + HOEHE)
set N2=Dreieck
set /a S=(SEITE_A + SEITE_B + SEITE_C) / 2
set /a RAD=S * (S - SEITE_A) * (S - SEITE_B) * (S - SEITE_C)
call :wurzel %RAD%
set /a F2=!W!, U2=SEITE_A + SEITE_B + SEITE_C

rem nach Flaeche aufsteigend ordnen
if !F1! GTR !F2! (
    set TMP=!N1!& set N1=!N2!& set N2=!TMP!
    set TMP=!F1!& set F1=!F2!& set F2=!TMP!
    set TMP=!U1!& set U1=!U2!& set U2=!TMP!
)

for %%i in (1 2) do (
    call :ecken !N%%i!
    if !F%%i! GEQ 10 (set STATUS=gross) else (set STATUS=klein)
    echo !N%%i!: Flaeche=!F%%i! Umfang=!U%%i! !STATUS! Ecken=!ECKEN!
)

call :ggt 48 18
echo ggT(48, 18) = !GGT!

set PRIM=
for /l %%n in (2, 1, 30) do (
    call :ist_prim %%n
    if not errorlevel 1 set PRIM=!PRIM! %%n
)
echo Primzahlen bis 30:!PRIM!

call :wurzel %RADIKAND%
echo Wurzel(2000000) = !W!
echo Maske: %MASKE%
echo Skala: %SKALA%
endlocal
exit /b 0

:: --- Unterprogramme ------------------------------------------------

:wurzel
rem Ganzzahlige Wurzel nach Newton, Argument %1, Ergebnis in W
set /a X=%~1, I=0
if %X% LEQ 0 (set W=0& exit /b 0)
:wurzel_schleife
set /a NEU=(X + %~1 / X) / 2, I+=1
if !NEU! GEQ !X! (set W=!X!& exit /b 0)
if !I! GEQ %MAX_SCHRITTE% (set W=!NEU!& exit /b 0)
set X=!NEU!
goto wurzel_schleife

:ggt
rem Groesster gemeinsamer Teiler nach Euklid, Ergebnis in GGT
set /a A=%~1, B=%~2
:ggt_schleife
if !B! EQU 0 (set GGT=!A!& exit /b 0)
set /a REST=A %% B, A=B, B=REST
goto ggt_schleife

:ist_prim
rem Probedivision; errorlevel 0 = prim, 1 = nicht prim
set /a N=%~1, T=2
if !N! LSS 2 exit /b 1
:prim_schleife
set /a QUAD=T * T
if !QUAD! GTR !N! exit /b 0
set /a REST=N %% T
if !REST! EQU 0 exit /b 1
set /a T+=1
goto prim_schleife

:dreieck_ok
rem Dreiecksungleichung; errorlevel 1 = ungueltig
set /a SUM1=%~1 + %~2, SUM2=%~1 + %~3, SUM3=%~2 + %~3
if !SUM1! LEQ %~3 exit /b 1
if !SUM2! LEQ %~2 exit /b 1
if !SUM3! LEQ %~1 exit /b 1
exit /b 0

:ecken
if "%~1"=="Dreieck" (set ECKEN=3& exit /b 0)
if "%~1"=="Rechteck" (set ECKEN=4& exit /b 0)
if "%~1"=="Kreis" (set ECKEN=0& exit /b 0)
set ECKEN=-1
exit /b 0
