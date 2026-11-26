*&---------------------------------------------------------------------*
*& Report  ZFORMEN
*& Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
*& Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
*& ABAP (ab 7.40).  Starten: Report in SE38 anlegen und ausfuehren (F8).
*&---------------------------------------------------------------------*
REPORT zformen.

CONSTANTS: gc_pi          TYPE f VALUE '3.141592653589793',
           gc_eps         TYPE f VALUE '1E-9',
           gc_max_schritte TYPE i VALUE 50.

"! Eigene Ausnahme fuer ungueltige Masse.
CLASS lcx_form_fehler DEFINITION INHERITING FROM cx_static_check.
  PUBLIC SECTION.
    DATA mv_text TYPE string READ-ONLY.
    METHODS constructor IMPORTING iv_text TYPE string.
ENDCLASS.

CLASS lcx_form_fehler IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_text = iv_text.
  ENDMETHOD.
ENDCLASS.

"! Gemeinsame Schnittstelle aller Formen.
INTERFACE lif_form.
  METHODS: flaeche RETURNING VALUE(rv_f) TYPE f,
           umfang  RETURNING VALUE(rv_u) TYPE f,
           ecken   RETURNING VALUE(rv_n) TYPE i,
           art     RETURNING VALUE(rv_a) TYPE string.
ENDINTERFACE.

CLASS lcl_mathe DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS: wurzel IMPORTING iv_v TYPE f RETURNING VALUE(rv_w) TYPE f,
                   fmt    IMPORTING iv_x TYPE f iv_n TYPE i RETURNING VALUE(rv_s) TYPE string,
                   ggt    IMPORTING iv_a TYPE i iv_b TYPE i RETURNING VALUE(rv_g) TYPE i,
                   ist_prim IMPORTING iv_n TYPE i RETURNING VALUE(rv_p) TYPE abap_bool.
ENDCLASS.

CLASS lcl_mathe IMPLEMENTATION.
  METHOD wurzel.                       " Quadratwurzel nach Newton
    DATA lv_x TYPE f.
    DATA lv_nx TYPE f.
    IF iv_v <= 0.
      rv_w = 0.
      RETURN.
    ENDIF.
    lv_x = iv_v.
    DO gc_max_schritte TIMES.
      lv_nx = ( lv_x + iv_v / lv_x ) / 2.
      IF abs( lv_nx - lv_x ) < gc_eps.
        rv_w = lv_nx.
        RETURN.
      ENDIF.
      lv_x = lv_nx.
    ENDDO.
    rv_w = lv_x.
  ENDMETHOD.
  METHOD fmt.
    DATA lv_p TYPE p LENGTH 16 DECIMALS 8.
    lv_p = iv_x.
    rv_s = |{ lv_p DECIMALS = iv_n }|.
  ENDMETHOD.
  METHOD ggt.
    DATA(lv_a) = iv_a.
    DATA(lv_b) = iv_b.
    WHILE lv_b <> 0.
      DATA(lv_r) = lv_a MOD lv_b.
      lv_a = lv_b.
      lv_b = lv_r.
    ENDWHILE.
    rv_g = lv_a.
  ENDMETHOD.
  METHOD ist_prim.
    DATA lv_t TYPE i VALUE 2.
    IF iv_n < 2.
      rv_p = abap_false.
      RETURN.
    ENDIF.
    WHILE lv_t * lv_t <= iv_n.
      IF iv_n MOD lv_t = 0.
        rv_p = abap_false.
        RETURN.
      ENDIF.
      lv_t = lv_t + 1.
    ENDWHILE.
    rv_p = abap_true.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_kreis DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_form.
    METHODS constructor IMPORTING iv_r TYPE f.
  PRIVATE SECTION.
    DATA mv_r TYPE f.
ENDCLASS.
CLASS lcl_kreis IMPLEMENTATION.
  METHOD constructor. mv_r = iv_r. ENDMETHOD.
  METHOD lif_form~flaeche. rv_f = gc_pi * mv_r * mv_r. ENDMETHOD.
  METHOD lif_form~umfang.  rv_u = 2 * gc_pi * mv_r. ENDMETHOD.
  METHOD lif_form~ecken.   rv_n = 0. ENDMETHOD.
  METHOD lif_form~art.     rv_a = `Kreis`. ENDMETHOD.
ENDCLASS.

CLASS lcl_rechteck DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_form.
    METHODS constructor IMPORTING iv_a TYPE f iv_b TYPE f.
  PRIVATE SECTION.
    DATA: mv_a TYPE f, mv_b TYPE f.
ENDCLASS.
CLASS lcl_rechteck IMPLEMENTATION.
  METHOD constructor. mv_a = iv_a. mv_b = iv_b. ENDMETHOD.
  METHOD lif_form~flaeche. rv_f = mv_a * mv_b. ENDMETHOD.
  METHOD lif_form~umfang.  rv_u = 2 * ( mv_a + mv_b ). ENDMETHOD.
  METHOD lif_form~ecken.   rv_n = 4. ENDMETHOD.
  METHOD lif_form~art.     rv_a = `Rechteck`. ENDMETHOD.
ENDCLASS.

CLASS lcl_dreieck DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_form.
    METHODS constructor IMPORTING iv_a TYPE f iv_b TYPE f iv_c TYPE f
                        RAISING lcx_form_fehler.
  PRIVATE SECTION.
    DATA: mv_a TYPE f, mv_b TYPE f, mv_c TYPE f.
ENDCLASS.
CLASS lcl_dreieck IMPLEMENTATION.
  METHOD constructor.
    IF iv_a + iv_b <= iv_c OR iv_a + iv_c <= iv_b OR iv_b + iv_c <= iv_a.
      RAISE EXCEPTION NEW lcx_form_fehler( |Dreieck { lcl_mathe=>fmt( iv_x = iv_a iv_n = 1 ) }/{
        lcl_mathe=>fmt( iv_x = iv_b iv_n = 1 ) }/{ lcl_mathe=>fmt( iv_x = iv_c iv_n = 1 ) } ungueltig| ).
    ENDIF.
    mv_a = iv_a. mv_b = iv_b. mv_c = iv_c.
  ENDMETHOD.
  METHOD lif_form~flaeche.
    DATA(lv_s) = CONV f( ( mv_a + mv_b + mv_c ) / 2 ).
    rv_f = lcl_mathe=>wurzel( lv_s * ( lv_s - mv_a ) * ( lv_s - mv_b ) * ( lv_s - mv_c ) ).
  ENDMETHOD.
  METHOD lif_form~umfang.  rv_u = mv_a + mv_b + mv_c. ENDMETHOD.
  METHOD lif_form~ecken.   rv_n = 3. ENDMETHOD.
  METHOD lif_form~art.     rv_a = `Dreieck`. ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  TYPES: BEGIN OF ty_eintrag,
           flaeche TYPE f,
           form    TYPE REF TO lif_form,
         END OF ty_eintrag.
  DATA: lt_formen TYPE STANDARD TABLE OF ty_eintrag WITH EMPTY KEY,
        lo_form   TYPE REF TO lif_form,
        lv_liste  TYPE string.

  WRITE / 'Formen-Rechner'.
  lt_formen = VALUE #( ( form = NEW lcl_kreis( '2.5' ) ) ( form = NEW lcl_rechteck( iv_a = '4.0' iv_b = '3.0' ) ) ).
  DO 2 TIMES.
    DATA(lv_b) = SWITCH f( sy-index WHEN 1 THEN '4.0' ELSE '2.0' ).
    DATA(lv_a) = SWITCH f( sy-index WHEN 1 THEN '3.0' ELSE '1.0' ).
    DATA(lv_c) = SWITCH f( sy-index WHEN 1 THEN '5.0' ELSE '10.0' ).
    TRY.
        APPEND VALUE #( form = NEW lcl_dreieck( iv_a = lv_a iv_b = lv_b iv_c = lv_c ) ) TO lt_formen.
      CATCH lcx_form_fehler INTO DATA(lx).
        WRITE / |Fehler: { lx->mv_text }|.
    ENDTRY.
  ENDDO.
  LOOP AT lt_formen ASSIGNING FIELD-SYMBOL(<e>).
    <e>-flaeche = <e>-form->flaeche( ).
  ENDLOOP.
  SORT lt_formen BY flaeche ASCENDING.
  LOOP AT lt_formen ASSIGNING <e>.
    DATA(lv_status) = COND string( WHEN <e>-flaeche >= '10.0' THEN `gross` ELSE `klein` ).
    WRITE / |{ <e>-form->art( ) }: Flaeche={ lcl_mathe=>fmt( iv_x = <e>-flaeche iv_n = 2 ) } Umfang={
      lcl_mathe=>fmt( iv_x = <e>-form->umfang( ) iv_n = 2 ) } { lv_status } Ecken={ <e>-form->ecken( ) }|.
  ENDLOOP.
  WRITE / |ggT(48, 18) = { lcl_mathe=>ggt( iv_a = 48 iv_b = 18 ) }|.
  DO 29 TIMES.
    DATA(lv_n) = sy-index + 1.
    IF lcl_mathe=>ist_prim( lv_n ) = abap_true.
      lv_liste = lv_liste && | { lv_n }|.
    ENDIF.
  ENDDO.
  WRITE / |Primzahlen bis 30:{ lv_liste }|.
  WRITE / |Wurzel(2) = { lcl_mathe=>fmt( iv_x = lcl_mathe=>wurzel( 2 ) iv_n = 8 ) }|.
  DATA(lv_maske) = CONV i( CONV xstring( 'FF' ) BIT-AND CONV xstring( 'AA' ) ).   " kein Binaerliteral in ABAP
  WRITE / |Maske: { lv_maske }|.
  WRITE / |Skala: { 1000000 DIV 8 }|.
