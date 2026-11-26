//! Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
//! Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
//! Start: zig run 37_zig.zig   (getestet mit Zig 0.17-dev)
const std = @import("std");

const kreiszahl = 3.141592653589793; // Kreiszahl
const eps = 1e-9; // Abbruchschwelle fuer Newton
const max_schritte = 50;
const maske = 0xFF & 0b10101010; // Hex- und Binaerliteral
const skala = 1_000_000 / 8;

/// Fehlerarten: Zig-Fehler tragen keinen Text, nur einen Namen.
const FormFehler = error{ KreisUngueltig, RechteckUngueltig, DreieckUngueltig };

/// Quadratwurzel nach Newton: neu = (alt + x / alt) / 2.
fn wurzel(x: f64) f64 {
    if (x <= 0) return 0.0;
    var alt = x;
    var i: usize = 0;
    while (i < max_schritte) : (i += 1) {
        const neu = 0.5 * (alt + x / alt);
        if (@abs(neu - alt) < eps) return neu;
        alt = neu;
    }
    return alt;
}

/// Groesster gemeinsamer Teiler nach Euklid.
fn ggt(a0: u32, b0: u32) u32 {
    var a = a0;
    var b = b0;
    while (b != 0) {
        const rest = a % b;
        a = b;
        b = rest;
    }
    return a;
}

/// Primzahltest durch Probedivision bis zur Wurzel von n.
fn istPrim(n: u32) bool {
    if (n < 2) return false;
    var i: u32 = 2;
    while (i * i <= n) : (i += 1) {
        if (n % i == 0) return false;
    }
    return true;
}

/// Alle Formen als getaggte Union.
const Form = union(enum) {
    kreis: struct { r: f64 },
    rechteck: struct { breite: f64, hoehe: f64 },
    dreieck: struct { a: f64, b: f64, c: f64 },

    fn kreisNeu(r: f64) FormFehler!Form {
        if (r <= 0) return error.KreisUngueltig;
        return .{ .kreis = .{ .r = r } };
    }

    fn rechteckNeu(b: f64, h: f64) FormFehler!Form {
        if (b <= 0 or h <= 0) return error.RechteckUngueltig;
        return .{ .rechteck = .{ .breite = b, .hoehe = h } };
    }

    fn dreieckNeu(a: f64, b: f64, c: f64) FormFehler!Form {
        if (a + b <= c or a + c <= b or b + c <= a) return error.DreieckUngueltig;
        return .{ .dreieck = .{ .a = a, .b = b, .c = c } };
    }

    fn name(self: Form) []const u8 {
        return switch (self) {
            .kreis => "Kreis",
            .rechteck => "Rechteck",
            .dreieck => "Dreieck",
        };
    }

    fn umfang(self: Form) f64 {
        return switch (self) {
            .kreis => |k| 2 * kreiszahl * k.r,
            .rechteck => |r| 2 * (r.breite + r.hoehe),
            .dreieck => |d| d.a + d.b + d.c,
        };
    }

    fn flaeche(self: Form) f64 {
        return switch (self) {
            .kreis => |k| kreiszahl * k.r * k.r,
            .rechteck => |r| r.breite * r.hoehe,
            .dreieck => |d| blk: {
                const s = (d.a + d.b + d.c) / 2; // Satz des Heron
                break :blk wurzel(s * (s - d.a) * (s - d.b) * (s - d.c));
            },
        };
    }

    fn ecken(self: Form) i32 {
        return switch (self) {
            .dreieck => 3,
            .rechteck => 4,
            .kreis => 0,
        };
    }
};

fn kleiner(_: void, x: Form, y: Form) bool {
    return x.flaeche() < y.flaeche();
}

pub fn main(init: std.process.Init) !void {
    var puffer: [4096]u8 = undefined;
    var datei = std.Io.File.stdout().writer(init.io, &puffer);
    const out = &datei.interface;

    try out.print("Formen-Rechner\n", .{});
    var formen: [4]Form = undefined;
    var anzahl: usize = 0;

    formen[anzahl] = try Form.kreisNeu(2.5);
    anzahl += 1;
    formen[anzahl] = try Form.rechteckNeu(4.0, 3.0);
    anzahl += 1;
    formen[anzahl] = try Form.dreieckNeu(3.0, 4.0, 5.0);
    anzahl += 1;
    if (Form.dreieckNeu(1.0, 2.0, 10.0)) |f| { // TODO: weitere Formen
        formen[anzahl] = f;
        anzahl += 1;
    } else |fehler| switch (fehler) {
        error.DreieckUngueltig => try out.print("Fehler: Dreieck {d:.1}/{d:.1}/{d:.1} ungueltig\n", .{ 1.0, 2.0, 10.0 }),
        else => return fehler,
    }

    std.mem.sort(Form, formen[0..anzahl], {}, kleiner);
    for (formen[0..anzahl]) |f| {
        const status = if (f.flaeche() >= 10.0) "gross" else "klein";
        try out.print("{s}: Flaeche={d:.2} Umfang={d:.2} {s} Ecken={d}\n", .{ f.name(), f.flaeche(), f.umfang(), status, f.ecken() });
    }
    try out.print("ggT(48, 18) = {d}\n", .{ggt(48, 18)});
    try out.print("Primzahlen bis 30:", .{});
    var n: u32 = 2;
    while (n <= 30) : (n += 1) {
        if (istPrim(n)) try out.print(" {d}", .{n});
    }
    try out.print("\nWurzel(2) = {d:.8}\n", .{wurzel(2.0)});
    try out.print("Maske: {d}\n", .{maske});
    try out.print("Skala: {d}\n", .{skala});
    try out.flush();
}
