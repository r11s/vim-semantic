# Formen-Rechner bauen. TODO: Paket erzeugen
CC      ?= gcc
CFLAGS  := -O2 -Wall $(EXTRA)
LDLIBS   = -lm
QUELLEN  = $(wildcard src/*.c) \
           main.c
OBJEKTE  = $(QUELLEN:.c=.o)
VERSION  ::= 1.0
DATUM    != date +%F
CFLAGS  += -DVERSION=\"$(VERSION)\"
export PFAD := ${HOME}/bin
override DEBUG = 1

-include abhaengig.d
include regeln.mk

ifeq ($(DEBUG),1)
  CFLAGS += -g
else ifneq ($(OS),Windows_NT)
  CFLAGS += -fPIC
endif
ifdef VERBOSE
Q =
else
Q = @
endif

.PHONY: all clean test
.SUFFIXES: .c .o

all: formen doc

formen: $(OBJEKTE)
	$(Q)$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)

%.o: %.c formen.h
	$(Q)$(CC) $(CFLAGS) -c $< -o $@   # Kommentar im Rezept

test: formen
	@echo "Starte Tests fuer $(VERSION)" && ./formen --test | tee log.txt
	-rm -f /tmp/formen.* 2>/dev/null
	+$(MAKE) -C tests all
	for f in $(QUELLEN); do echo $$f $${PWD}; done

doc: ; @echo keine

clean::
	rm -f $(OBJEKTE) formen

define HILFE
Ziele: all, test, clean
  $(1) = $@
endef

$(eval $(call vorlage,$(patsubst %.c,%,$(QUELLEN))))
LISTE := $(shell ls -1 | grep -v "^\\.")
$(info $(subst a,b,$(strip $(LISTE))))
