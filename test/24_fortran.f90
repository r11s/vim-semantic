! ------------------------------------------------------------------
! Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
! Eigener Code, frei verwendbar (CC0). Stand: 2026-11-24
! Uebersetzen: gfortran -std=f2008 -o formen 24_fortran.f90
! ------------------------------------------------------------------

!> Konstanten und Hilfsfunktionen
module zahlen
  implicit none
  real(8), parameter :: PI = 3.141592653589793d0   ! Kreiszahl
  real(8), parameter :: EPS = 1.0d-9               ! Abbruchschwelle fuer Newton
  integer, parameter :: MAX_SCHRITTE = 50
  integer, parameter :: MASKE = iand(int(z'FF'), int(b'10101010'))
  integer, parameter :: SKALA = 1000000 / 8
contains

  !> Quadratwurzel nach Newton: neu = (alt + x / alt) / 2
  function wurzel(x) result(w)
    real(8), intent(in) :: x
    real(8) :: w, alt, neu
    integer :: i
    w = 0.0d0
    if (x <= 0.0d0) return
    alt = x
    w = alt
    do i = 1, MAX_SCHRITTE
      neu = 0.5d0 * (alt + x / alt)
      w = neu
      if (abs(neu - alt) < EPS) return
      alt = neu
    end do
  end function wurzel

  !> Groesster gemeinsamer Teiler nach Euklid
  function ggt(a0, b0) result(a)
    integer, intent(in) :: a0, b0
    integer :: a, b, rest
    a = a0
    b = b0
    do while (b /= 0)
      rest = mod(a, b)
      a = b
      b = rest
    end do
  end function ggt

  !> Primzahltest durch Probedivision bis zur Wurzel von n
  function ist_prim(n) result(prim)
    integer, intent(in) :: n
    logical :: prim
    integer :: i
    prim = .false.
    if (n < 2) return
    i = 2
    do while (i * i <= n)
      if (mod(n, i) == 0) return
      i = i + 1
    end do
    prim = .true.
  end function ist_prim
end module zahlen

!> Formen als erweiterbare Typen
module formen
  use zahlen
  implicit none

  type, abstract :: form
    character(len=8) :: bezeichnung = ''
  contains
    procedure(mass), deferred :: flaeche
    procedure(mass), deferred :: umfang
  end type form

  abstract interface
    function mass(self) result(m)
      import :: form
      class(form), intent(in) :: self
      real(8) :: m
    end function mass
  end interface

  type, extends(form) :: kreis
    real(8) :: r
  contains
    procedure :: flaeche => kreis_flaeche
    procedure :: umfang => kreis_umfang
  end type kreis

  type, extends(form) :: rechteck
    real(8) :: breite, hoehe
  contains
    procedure :: flaeche => rechteck_flaeche
    procedure :: umfang => rechteck_umfang
  end type rechteck

  type, extends(form) :: dreieck
    real(8) :: a, b, c
  contains
    procedure :: flaeche => dreieck_flaeche
    procedure :: umfang => dreieck_umfang
  end type dreieck

  type :: huelle
    class(form), allocatable :: f
  end type huelle

contains
  function kreis_flaeche(self) result(m)
    class(kreis), intent(in) :: self
    real(8) :: m
    m = PI * self%r**2
  end function kreis_flaeche

  function kreis_umfang(self) result(m)
    class(kreis), intent(in) :: self
    real(8) :: m
    m = 2.0d0 * PI * self%r
  end function kreis_umfang

  function rechteck_flaeche(self) result(m)
    class(rechteck), intent(in) :: self
    real(8) :: m
    m = self%breite * self%hoehe
  end function rechteck_flaeche

  function rechteck_umfang(self) result(m)
    class(rechteck), intent(in) :: self
    real(8) :: m
    m = 2.0d0 * (self%breite + self%hoehe)
  end function rechteck_umfang

  function dreieck_umfang(self) result(m)
    class(dreieck), intent(in) :: self
    real(8) :: m
    m = self%a + self%b + self%c
  end function dreieck_umfang

  function dreieck_flaeche(self) result(m)
    class(dreieck), intent(in) :: self
    real(8) :: m, s
    s = self%umfang() / 2.0d0     ! Satz des Heron
    m = wurzel(s * (s - self%a) * (s - self%b) * (s - self%c))
  end function dreieck_flaeche

  function ecken(f) result(n)
    class(form), intent(in) :: f
    integer :: n
    select case (trim(f%bezeichnung))
    case ('Dreieck')
      n = 3
    case ('Rechteck')
      n = 4
    case ('Kreis')
      n = 0
    case default
      n = -1
    end select
  end function ecken
end module formen

program formen_rechner
  use formen
  implicit none
  type(huelle) :: liste(3)
  integer :: reihe(3)
  integer :: i, j, k, n
  character(len=6) :: status

  print '(a)', 'Formen-Rechner'
  allocate(liste(1)%f, source=kreis('Kreis', 2.5d0))
  allocate(liste(2)%f, source=rechteck('Rechteck', 4.0d0, 3.0d0))
  allocate(liste(3)%f, source=dreieck('Dreieck', 3.0d0, 4.0d0, 5.0d0))
  ! TODO: Fortran kennt keine Ausnahmen, daher wird vorab geprueft
  if (1.0d0 + 2.0d0 <= 10.0d0) print '(a)', 'Fehler: Dreieck 1.0/2.0/10.0 ungueltig'

  reihe = [1, 2, 3]
  do i = 1, 2                      ! Sortieren nach Flaeche (Bubblesort ueber Indizes)
    do j = 1, 3 - i
      if (liste(reihe(j))%f%flaeche() > liste(reihe(j + 1))%f%flaeche()) then
        k = reihe(j)
        reihe(j) = reihe(j + 1)
        reihe(j + 1) = k
      end if
    end do
  end do

  do i = 1, 3
    k = reihe(i)
    status = merge('gross ', 'klein ', liste(k)%f%flaeche() >= 10.0d0)
    print '(a,": Flaeche=",f0.2," Umfang=",f0.2," ",a," Ecken=",i0)', &
      trim(liste(k)%f%bezeichnung), liste(k)%f%flaeche(), liste(k)%f%umfang(), &
      trim(status), ecken(liste(k)%f)
  end do
  print '(a,i0)', 'ggT(48, 18) = ', ggt(48, 18)
  write (*, '(a)', advance='no') 'Primzahlen bis 30:'
  do n = 2, 30
    if (ist_prim(n)) write (*, '(a,i0)', advance='no') ' ', n
  end do
  print *
  print '(a,f0.8)', 'Wurzel(2) = ', wurzel(2.0d0)
  print '(a,i0)', 'Maske: ', MASKE
  print '(a,i0)', 'Skala: ', SKALA
end program formen_rechner
