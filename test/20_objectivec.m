// ------------------------------------------------------------------
// Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
// Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
// Foundation (Apple oder GNUstep). Beispiel (macOS): clang -fobjc-arc -framework Foundation
// ------------------------------------------------------------------
#import <Foundation/Foundation.h>
#include <math.h>

#define PI_WERT 3.141592653589793      /* Kreiszahl */
#define EPS 1e-9                       /* Abbruchschwelle fuer Newton */
#define MAX_SCHRITTE 50
#define MASKE (0xFF & 0b10101010)      /* Hex- und Binaerliteral */
#define SKALA (1000000 / 8)

typedef enum { ArtKreis, ArtRechteck, ArtDreieck } Art;

static NSString *const FormFehler = @"FormFehler";

static void ausgabe(NSString *text) {
    puts([text UTF8String]);
}

/// Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
static double wurzel(double x) {
    if (x <= 0) return 0.0;
    double alt = x;
    for (int i = 0; i < MAX_SCHRITTE; i++) {
        double neu = 0.5 * (alt + x / alt);
        if (fabs(neu - alt) < EPS) return neu;
        alt = neu;
    }
    return alt;
}

/// Groesster gemeinsamer Teiler nach Euklid.
static NSInteger ggt(NSInteger a, NSInteger b) {
    while (b != 0) {
        NSInteger rest = a % b;
        a = b;
        b = rest;
    }
    return a;
}

/// Primzahltest durch Probedivision bis zur Wurzel von n.
static BOOL istPrim(NSInteger n) {
    if (n < 2) return NO;
    for (NSInteger i = 2; i * i <= n; i++) {
        if (n % i == 0) return NO;
    }
    return YES;
}

#pragma mark - Protokoll und Basisklasse

/** Gemeinsame Schnittstelle aller Formen. */
@protocol Messbar <NSObject>
- (double)flaeche;
- (double)umfang;
@end

@interface Form : NSObject <Messbar>
@property (nonatomic, readonly) Art art;
- (NSString *)name;
@end

@implementation Form
- (Art)art { return ArtKreis; }
- (double)flaeche { return 0; }
- (double)umfang { return 0; }
- (NSString *)name { return NSStringFromClass([self class]); }
@end

#pragma mark - Konkrete Formen

@interface Kreis : Form {
    double _r;
}
- (instancetype)initMitRadius:(double)r;
@end

@implementation Kreis

- (instancetype)initMitRadius:(double)r {
    if (r <= 0) [NSException raise:FormFehler format:@"Kreis %.1f ungueltig", r];
    if ((self = [super init])) _r = r;
    return self;
}

- (Art)art { return ArtKreis; }
- (double)flaeche { return PI_WERT * _r * _r; }
- (double)umfang { return 2 * PI_WERT * _r; }
@end

@interface Rechteck : Form {
    double _breite, _hoehe;
}
- (instancetype)initMitBreite:(double)b hoehe:(double)h;
@end

@implementation Rechteck

- (instancetype)initMitBreite:(double)b hoehe:(double)h {
    if (b <= 0 || h <= 0) [NSException raise:FormFehler format:@"Rechteck %.1f/%.1f ungueltig", b, h];
    if ((self = [super init])) { _breite = b; _hoehe = h; }
    return self;
}

- (Art)art { return ArtRechteck; }
- (double)flaeche { return _breite * _hoehe; }
- (double)umfang { return 2 * (_breite + _hoehe); }
@end

@interface Dreieck : Form {
    double _a, _b, _c;
}
- (instancetype)initMitA:(double)a b:(double)b c:(double)c;
@end

@implementation Dreieck

- (instancetype)initMitA:(double)a b:(double)b c:(double)c {
    if (a + b <= c || a + c <= b || b + c <= a) {
        [NSException raise:FormFehler format:@"Dreieck %.1f/%.1f/%.1f ungueltig", a, b, c];
    }
    if ((self = [super init])) { _a = a; _b = b; _c = c; }
    return self;
}

- (Art)art { return ArtDreieck; }
- (double)umfang { return _a + _b + _c; }

- (double)flaeche {
    double s = [self umfang] / 2;   // Satz des Heron
    return wurzel(s * (s - _a) * (s - _b) * (s - _c));
}
@end

static int ecken(Form *form) {
    switch (form.art) {
        case ArtDreieck:  return 3;
        case ArtRechteck: return 4;
        case ArtKreis:    return 0;
        default:          return -1;
    }
}

int main(void) {
    @autoreleasepool {
        ausgabe(@"Formen-Rechner");
        NSMutableArray<Form *> *formen = [NSMutableArray arrayWithObjects:
            [[Kreis alloc] initMitRadius:2.5],
            [[Rechteck alloc] initMitBreite:4.0 hoehe:3.0],
            [[Dreieck alloc] initMitA:3.0 b:4.0 c:5.0], nil];
        @try {
            [formen addObject:[[Dreieck alloc] initMitA:1.0 b:2.0 c:10.0]];  // TODO: weitere Formen
        } @catch (NSException *fehler) {
            if (![fehler.name isEqualToString:FormFehler]) @throw;
            ausgabe([NSString stringWithFormat:@"Fehler: %@", fehler.reason]);
        }
        [formen sortUsingComparator:^NSComparisonResult(Form *x, Form *y) {
            double fx = [x flaeche], fy = [y flaeche];
            return fx < fy ? NSOrderedAscending : (fx > fy ? NSOrderedDescending : NSOrderedSame);
        }];
        for (Form *f in formen) {
            NSString *status = [f flaeche] >= 10.0 ? @"gross" : @"klein";
            ausgabe([NSString stringWithFormat:@"%@: Flaeche=%.2f Umfang=%.2f %@ Ecken=%d",
                     [f name], [f flaeche], [f umfang], status, ecken(f)]);
        }
        ausgabe([NSString stringWithFormat:@"ggT(48, 18) = %ld", (long)ggt(48, 18)]);
        NSMutableArray<NSString *> *prim = [NSMutableArray array];
        for (NSInteger n = 2; n <= 30; n++) {
            if (istPrim(n)) [prim addObject:[NSString stringWithFormat:@"%ld", (long)n]];
        }
        ausgabe([@"Primzahlen bis 30: " stringByAppendingString:[prim componentsJoinedByString:@" "]]);
        ausgabe([NSString stringWithFormat:@"Wurzel(2) = %.8f", wurzel(2)]);
        ausgabe([NSString stringWithFormat:@"Maske: %d", MASKE]);
        ausgabe([NSString stringWithFormat:@"Skala: %d", SKALA]);
    }
    return 0;
}
