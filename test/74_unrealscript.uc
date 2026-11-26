//=============================================================================
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
// UnrealScript (UE2/UE3): eine Klasse pro Datei, Ausgabe ueber log().
// Starten: Klasse FormenRechner im Spiel/Editor spawnen (PostBeginPlay).
// UnrealScript kennt keine Ausnahmen: Fehler = Rueckgabewert.
//=============================================================================
class FormenRechner extends Info;

const PI_WERT = 3.141592653589793;
const EPS = 0.000001;
const MAX_SCHRITTE = 50;

enum EArt
{
    ART_Kreis,
    ART_Rechteck,
    ART_Dreieck
};

/** Eine Form: Art und bis zu drei Masse. */
struct Form
{
    var EArt Art;
    var float A;
    var float B;
    var float C;
};

var array<Form> Gueltig;

// Zahl mit n Nachkommastellen als Text
static function string Fmt(float X, int N)
{
    local int Skal, Wert, I;
    local string Rest;
    Skal = 1;
    for (I = 0; I < N; I++)
        Skal *= 10;
    Wert = int(X * Skal + 0.5);
    Rest = string(Wert % Skal);
    while (Len(Rest) < N)
        Rest = "0" $ Rest;
    return string(Wert / Skal) $ "." $ Rest;
}

// Quadratwurzel nach Newton
static function float Wurzel(float V)
{
    local float X, NX;
    local int I;
    if (V <= 0.0)
        return 0.0;
    X = V;
    for (I = 0; I < MAX_SCHRITTE; I++)
    {
        NX = 0.5 * (X + V / X);
        if (Abs(NX - X) < EPS)
            return NX;
        X = NX;
    }
    return X;
}

static function string ArtName(EArt A)
{
    switch (A)
    {
        case ART_Kreis:    return "Kreis";
        case ART_Rechteck: return "Rechteck";
        default:           return "Dreieck";
    }
}

static function bool IstGueltig(Form F)
{
    switch (F.Art)
    {
        case ART_Kreis:    return F.A > 0;
        case ART_Rechteck: return F.A > 0 && F.B > 0;
        default:           return F.A + F.B > F.C && F.A + F.C > F.B && F.B + F.C > F.A;
    }
}

static function float Flaeche(Form F)
{
    local float S;
    switch (F.Art)
    {
        case ART_Kreis:    return PI_WERT * F.A * F.A;
        case ART_Rechteck: return F.A * F.B;
        default:
            S = (F.A + F.B + F.C) / 2;
            return Wurzel(S * (S - F.A) * (S - F.B) * (S - F.C));
    }
}

static function float Umfang(Form F)
{
    switch (F.Art)
    {
        case ART_Kreis:    return 2 * PI_WERT * F.A;
        case ART_Rechteck: return 2 * (F.A + F.B);
        default:           return F.A + F.B + F.C;
    }
}

static function int Ecken(Form F)
{
    switch (F.Art)
    {
        case ART_Kreis:    return 0;
        case ART_Rechteck: return 4;
        case ART_Dreieck:  return 3;
        default:           return -1;
    }
}

static function int Ggt(int A, int B)
{
    local int R;
    while (B != 0)
    {
        R = A % B;
        A = B;
        B = R;
    }
    return A;
}

static function bool IstPrim(int N)
{
    local int T;
    if (N < 2)
        return false;
    for (T = 2; T * T <= N; T++)
        if (N % T == 0)
            return false;
    return true;
}

static function Form NeueForm(EArt Art, float A, float B, float C)
{
    local Form F;
    F.Art = Art; F.A = A; F.B = B; F.C = C;
    return F;
}

function PostBeginPlay()
{
    local array<Form> Alle;
    local Form Tmp;
    local int I, J, N;
    local string Liste, Status;

    log("Formen-Rechner");
    Alle[0] = NeueForm(ART_Kreis, 2.5, 0, 0);
    Alle[1] = NeueForm(ART_Rechteck, 4.0, 3.0, 0);
    Alle[2] = NeueForm(ART_Dreieck, 3.0, 4.0, 5.0);
    Alle[3] = NeueForm(ART_Dreieck, 1.0, 2.0, 10.0);   // TODO: weitere Formen
    for (I = 0; I < Alle.Length; I++)
    {
        if (IstGueltig(Alle[I]))
            Gueltig[Gueltig.Length] = Alle[I];
        else
            log("Fehler: Dreieck " $ Fmt(Alle[I].A, 1) $ "/" $ Fmt(Alle[I].B, 1) $ "/" $ Fmt(Alle[I].C, 1) $ " ungueltig");
    }
    // Sortieren nach Flaeche (Bubblesort)
    N = Gueltig.Length;
    for (I = 0; I < N - 1; I++)
        for (J = 0; J < N - 1 - I; J++)
            if (Flaeche(Gueltig[J]) > Flaeche(Gueltig[J + 1]))
            {
                Tmp = Gueltig[J];
                Gueltig[J] = Gueltig[J + 1];
                Gueltig[J + 1] = Tmp;
            }
    for (I = 0; I < N; I++)
    {
        Status = Flaeche(Gueltig[I]) >= 10.0 ? "gross" : "klein";
        log(ArtName(Gueltig[I].Art) $ ": Flaeche=" $ Fmt(Flaeche(Gueltig[I]), 2)
            $ " Umfang=" $ Fmt(Umfang(Gueltig[I]), 2) $ " " $ Status $ " Ecken=" $ Ecken(Gueltig[I]));
    }
    log("ggT(48, 18) = " $ Ggt(48, 18));
    for (I = 2; I <= 30; I++)
        if (IstPrim(I))
            Liste = Liste $ " " $ I;
    log("Primzahlen bis 30:" $ Liste);
    log("Wurzel(2) = " $ Fmt(Wurzel(2.0), 8));
    log("Maske: " $ (0xFF & 0xAA));         // kein Binaerliteral in UnrealScript
    log("Skala: " $ (1000000 / 8));
}

defaultproperties
{
}
