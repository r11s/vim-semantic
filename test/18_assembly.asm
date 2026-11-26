; ------------------------------------------------------------------
; Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
; Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
; NASM, x86-64 Linux, nur Ganzzahlen (kein Kreis, Wurzel skaliert).
; Bauen: nasm -f elf64 18_assembly.asm -o f.o && ld -o f f.o && ./f
; ------------------------------------------------------------------
%define MAX_SCHRITTE 50                 ; Obergrenze fuer das Newton-Verfahren
MASKE     equ 0xFF & 10101010b          ; Hex- und Binaerliteral
SKALA     equ 1000000 / 8               ; Ganzzahldivision
RADIKAND  equ 2 * 1000000               ; Wurzel(2) mit sechs Nachkommastellen
BREITE    equ 4
HOEHE     equ 3
SEITE_A   equ 3
SEITE_B   equ 4
SEITE_C   equ 5
ANZAHL    equ 2

%macro ausgabe 1                        ; schreibt String %1 samt Laenge %1_len
    mov rsi, %1
    mov rdx, %1_len
    call schreibe
%endmacro

section .data
titel:      db "Formen-Rechner (Assembly, nur ganze Zahlen)", 10
titel_len   equ $ - titel
fehler:     db "Fehler: Dreieck 1/2/10 ungueltig", 10
fehler_len  equ $ - fehler
n_rechteck: db "Rechteck"
n_dreieck:  db "Dreieck"
namen:      dq n_rechteck, 8, n_dreieck, 7      ; Zeiger und Laenge je Art
s_flaeche:  db ": Flaeche="
s_flaeche_len equ $ - s_flaeche
s_umfang:   db " Umfang="
s_umfang_len equ $ - s_umfang
s_gross:    db " gross Ecken="
s_gross_len equ $ - s_gross
s_klein:    db " klein Ecken="
s_klein_len equ $ - s_klein
s_ggt:      db "ggT(48, 18) = "
s_ggt_len   equ $ - s_ggt
s_prim:     db "Primzahlen bis 30:"
s_prim_len  equ $ - s_prim
s_wurzel:   db "Wurzel(2000000) = "
s_wurzel_len equ $ - s_wurzel
s_maske:    db "Maske: "
s_maske_len equ $ - s_maske
s_skala:    db "Skala: "
s_skala_len equ $ - s_skala
leer:       db " "
leer_len    equ 1
zeile:      db 10
zeile_len   equ 1

section .bss
puffer:     resb 24                     ; Platz fuer eine Dezimalzahl
formen:     resq 3 * ANZAHL             ; je Eintrag: Art, Flaeche, Umfang

section .text
global _start

; schreibe: rsi = Zeiger, rdx = Laenge -> stdout
schreibe:
    mov eax, 1                          ; Systemaufruf write
    mov edi, 1
    syscall
    ret

; schreibe_zahl: rdi = Zahl ohne Vorzeichen, Ausgabe dezimal
schreibe_zahl:
    mov rax, rdi
    lea rsi, [puffer + 24]
    mov rcx, 10
.ziffer:
    xor edx, edx
    div rcx                             ; Rest = letzte Ziffer
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .ziffer
    lea rdx, [puffer + 24]
    sub rdx, rsi
    jmp schreibe

; ggt: Euklid, rdi = a, rsi = b -> rax
ggt:
.schleife:
    test rsi, rsi
    jz .fertig
    mov rax, rdi
    xor edx, edx
    div rsi
    mov rdi, rsi
    mov rsi, rdx
    jmp .schleife
.fertig:
    mov rax, rdi
    ret

; ist_prim: Probedivision, rdi = n -> eax (1 = prim)
ist_prim:
    xor eax, eax
    cmp rdi, 2
    jb .ende
    mov rcx, 2
.teste:
    mov rax, rcx
    mul rcx                             ; rax = i * i
    cmp rax, rdi
    ja .prim
    mov rax, rdi
    xor edx, edx
    div rcx
    test rdx, rdx
    jz .nein
    inc rcx
    jmp .teste
.prim:
    mov eax, 1
    ret
.nein:
    xor eax, eax
.ende:
    ret

; wurzel: ganzzahliges Newton-Verfahren, rdi = v -> rax
wurzel:
    mov rax, rdi
    test rdi, rdi
    jz .null
    mov r8d, MAX_SCHRITTE
.runde:
    mov rcx, rax                        ; alt
    mov rax, rdi
    xor edx, edx
    div rcx
    add rax, rcx
    shr rax, 1                          ; neu = (alt + v / alt) / 2
    cmp rax, rcx
    jae .stabil
    dec r8
    jnz .runde
    ret
.stabil:
    mov rax, rcx
.null:
    ret

; dreieck_ok: rdi, rsi, rdx = Seiten -> eax (1 = Dreiecksungleichung erfuellt)
dreieck_ok:
    lea rax, [rdi + rsi]
    cmp rax, rdx
    jbe .nein
    lea rax, [rdi + rdx]
    cmp rax, rsi
    jbe .nein
    lea rax, [rsi + rdx]
    cmp rax, rdi
    jbe .nein
    mov eax, 1
    ret
.nein:
    xor eax, eax
    ret

; dreieck_flaeche: Satz des Heron, rdi, rsi, rdx = Seiten -> rax
dreieck_flaeche:
    lea rax, [rdi + rsi]
    add rax, rdx
    shr rax, 1                          ; s = Umfang / 2
    mov r9, rax
    mov r10, r9
    sub r10, rdi
    imul rax, r10
    mov r10, r9
    sub r10, rsi
    imul rax, r10
    mov r10, r9
    sub r10, rdx
    imul rax, r10
    mov rdi, rax
    jmp wurzel

; ecken: rdi = Art (0 Rechteck, 1 Dreieck) -> rax
ecken:
    cmp rdi, 0
    je .vier
    cmp rdi, 1
    je .drei
    xor eax, eax
    ret
.vier:
    mov eax, 4
    ret
.drei:
    mov eax, 3
    ret

_start:
    ausgabe titel
    mov rdi, 1                          ; TODO: weitere Formen
    mov rsi, 2
    mov rdx, 10
    call dreieck_ok
    test eax, eax
    jnz .gueltig
    ausgabe fehler
.gueltig:
    mov qword [formen], 0               ; Rechteck
    mov qword [formen + 8], BREITE * HOEHE
    mov qword [formen + 16], 2 * (BREITE + HOEHE)
    mov qword [formen + 24], 1          ; Dreieck
    mov rdi, SEITE_A
    mov rsi, SEITE_B
    mov rdx, SEITE_C
    call dreieck_flaeche
    mov [formen + 32], rax
    mov qword [formen + 40], SEITE_A + SEITE_B + SEITE_C

    mov rax, [formen + 8]               ; nach Flaeche aufsteigend ordnen
    cmp rax, [formen + 32]
    jbe .geordnet
%assign i 0
%rep 3
    mov rax, [formen + i * 8]
    xchg rax, [formen + 24 + i * 8]
    mov [formen + i * 8], rax
%assign i i + 1
%endrep
.geordnet:
    mov r12, formen
    mov r13, ANZAHL
.naechste:
    mov rax, [r12]
    shl rax, 4
    lea rbx, [namen + rax]
    mov rsi, [rbx]
    mov rdx, [rbx + 8]
    call schreibe
    ausgabe s_flaeche
    mov rdi, [r12 + 8]
    call schreibe_zahl
    ausgabe s_umfang
    mov rdi, [r12 + 16]
    call schreibe_zahl
    cmp qword [r12 + 8], 10
    jae .gross
    ausgabe s_klein
    jmp .ecken
.gross:
    ausgabe s_gross
.ecken:
    mov rdi, [r12]
    call ecken
    mov rdi, rax
    call schreibe_zahl
    ausgabe zeile
    add r12, 24
    dec r13
    jnz .naechste

    mov rdi, 48
    mov rsi, 18
    call ggt
    mov rbx, rax
    ausgabe s_ggt
    mov rdi, rbx
    call schreibe_zahl
    ausgabe zeile

    ausgabe s_prim
    mov r12, 2
.pruefe:
    mov rdi, r12
    call ist_prim
    test eax, eax
    jz .weiter
    ausgabe leer
    mov rdi, r12
    call schreibe_zahl
.weiter:
    inc r12
    cmp r12, 30
    jbe .pruefe
    ausgabe zeile

    mov rdi, RADIKAND
    call wurzel
    mov rbx, rax
    ausgabe s_wurzel
    mov rdi, rbx
    call schreibe_zahl
    ausgabe zeile
    ausgabe s_maske
    mov rdi, MASKE
    call schreibe_zahl
    ausgabe zeile
    ausgabe s_skala
    mov rdi, SKALA
    call schreibe_zahl
    ausgabe zeile

    mov eax, 60                         ; exit(0)
    xor edi, edi
    syscall
