// SPDX-License-Identifier: CC0-1.0
/* ------------------------------------------------------------------
 * Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
 * Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
 * Solidity kennt keine Gleitkommazahlen: Festkomma mit Skala 1e8.
 * Pruefen: solcjs --abi 42_solidity.sol  (Ausgabe: Rueckgabewert von haupt())
 * ------------------------------------------------------------------ */
pragma solidity ^0.8.20;

/// @title Schnittstelle fuer Flaechenberechnungen
interface IMessbar {
    /// @notice Gibt die Ausgabezeilen des Programms zurueck.
    function haupt() external view returns (string memory);
}

/// @title Formen-Rechner
/// @dev Alle Masse sind Festkommazahlen mit SKALA Einheiten pro 1.0.
contract Formen is IMessbar {
    uint256 private constant SKALA = 1e8;
    uint256 private constant PI_WERT = 314159265; // Pi * SKALA
    uint256 private constant EPS = 1;
    uint256 private constant MAX_SCHRITTE = 50;

    enum Art { Kreis, Rechteck, Dreieck }

    struct Form {
        Art art;
        uint256 a;
        uint256 b;
        uint256 c;
    }

    function mul(uint256 x, uint256 y) private pure returns (uint256) {
        return (x * y) / SKALA;
    }

    /// @dev Quadratwurzel nach Newton (Festkomma).
    function wurzel(uint256 v) internal pure returns (uint256) {
        if (v == 0) return 0;
        uint256 x = v;
        for (uint256 i = 0; i < MAX_SCHRITTE; i++) {
            uint256 nx = (x + (v * SKALA) / x) / 2;
            uint256 diff = nx > x ? nx - x : x - nx;
            x = nx;
            if (diff <= EPS) break;
        }
        return x;
    }

    /// @dev Zahl mit n Nachkommastellen (gerundet) als Text.
    function fmt(uint256 x, uint256 n) internal pure returns (string memory) {
        uint256 p = 10 ** n;
        uint256 wert = (x * p + SKALA / 2) / SKALA;
        string memory rest = utoa(wert % p);
        while (bytes(rest).length < n) rest = string.concat("0", rest);
        return string.concat(utoa(wert / p), ".", rest);
    }

    function utoa(uint256 z) internal pure returns (string memory) {
        if (z == 0) return "0";
        uint256 laenge;
        for (uint256 t = z; t != 0; t /= 10) laenge++;
        bytes memory puffer = new bytes(laenge);
        while (z != 0) {
            laenge--;
            puffer[laenge] = bytes1(uint8(48 + (z % 10)));
            z /= 10;
        }
        return string(puffer);
    }

    function name(Art a) internal pure returns (string memory) {
        if (a == Art.Kreis) return "Kreis";
        if (a == Art.Rechteck) return "Rechteck";
        return "Dreieck";
    }

    /// @dev Wirft (revert) mit Meldung bei ungueltigen Massen.
    function pruefe(Form memory f) external pure {
        bool ok = true;
        string memory masse = fmt(f.a, 1);
        if (f.art == Art.Kreis) {
            ok = f.a > 0;
        } else if (f.art == Art.Rechteck) {
            ok = f.a > 0 && f.b > 0;
            masse = string.concat(masse, "/", fmt(f.b, 1));
        } else {
            ok = f.a + f.b > f.c && f.a + f.c > f.b && f.b + f.c > f.a;
            masse = string.concat(masse, "/", fmt(f.b, 1), "/", fmt(f.c, 1));
        }
        require(ok, string.concat(name(f.art), " ", masse, " ungueltig"));
    }

    function flaeche(Form memory f) internal pure returns (uint256) {
        if (f.art == Art.Kreis) return mul(mul(PI_WERT, f.a), f.a);
        if (f.art == Art.Rechteck) return mul(f.a, f.b);
        uint256 s = (f.a + f.b + f.c) / 2;
        return wurzel(mul(mul(s, s - f.a), mul(s - f.b, s - f.c)));
    }

    function umfang(Form memory f) internal pure returns (uint256) {
        if (f.art == Art.Kreis) return 2 * mul(PI_WERT, f.a);
        if (f.art == Art.Rechteck) return 2 * (f.a + f.b);
        return f.a + f.b + f.c;
    }

    function ecken(Form memory f) internal pure returns (uint256) {
        if (f.art == Art.Kreis) return 0;
        if (f.art == Art.Rechteck) return 4;
        return 3;
    }

    function ggt(uint256 a, uint256 b) internal pure returns (uint256) {
        while (b != 0) (a, b) = (b, a % b);
        return a;
    }

    function istPrim(uint256 n) internal pure returns (bool) {
        if (n < 2) return false;
        for (uint256 t = 2; t * t <= n; t++) {
            if (n % t == 0) return false;
        }
        return true;
    }

    function haupt() external view override returns (string memory) {
        string memory aus = "Formen-Rechner\n";
        Form[4] memory alle = [
            Form(Art.Kreis, 2.5e8, 0, 0),
            Form(Art.Rechteck, 4e8, 3e8, 0),
            Form(Art.Dreieck, 3e8, 4e8, 5e8),
            Form(Art.Dreieck, 1e8, 2e8, 10e8) // TODO: weitere Formen
        ];
        Form[] memory gueltig = new Form[](4);
        uint256 n = 0;
        for (uint256 i = 0; i < 4; i++) {
            try this.pruefe(alle[i]) {
                gueltig[n++] = alle[i];
            } catch Error(string memory meldung) {
                aus = string.concat(aus, "Fehler: ", meldung, "\n");
            }
        }
        // Sortieren nach Flaeche (Einfuegesortierung)
        for (uint256 i = 1; i < n; i++) {
            Form memory f = gueltig[i];
            uint256 j = i;
            while (j > 0 && flaeche(gueltig[j - 1]) > flaeche(f)) {
                gueltig[j] = gueltig[j - 1];
                j--;
            }
            gueltig[j] = f;
        }
        for (uint256 i = 0; i < n; i++) {
            Form memory f = gueltig[i];
            aus = string.concat(
                aus, name(f.art), ": Flaeche=", fmt(flaeche(f), 2), " Umfang=", fmt(umfang(f), 2),
                flaeche(f) >= 10e8 ? " gross" : " klein", " Ecken=", utoa(ecken(f)), "\n"
            );
        }
        aus = string.concat(aus, "ggT(48, 18) = ", utoa(ggt(48, 18)), "\n");
        aus = string.concat(aus, "Primzahlen bis 30:");
        for (uint256 p = 2; p <= 30; p++) {
            if (istPrim(p)) aus = string.concat(aus, " ", utoa(p));
        }
        aus = string.concat(aus, "\nWurzel(2) = ", fmt(wurzel(2 * SKALA), 8), "\n");
        aus = string.concat(aus, "Maske: ", utoa(0xFF & 0xAA), "\n"); // kein Binaerliteral in Solidity
        aus = string.concat(aus, "Skala: ", utoa(1_000_000 / 8));
        return aus;
    }
}
