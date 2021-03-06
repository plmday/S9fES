# Scheme 9 from Empty Space
# Makefile (obviously)
# By Nils M Holm, 2007-2012
# Placed in the Public Domain.

# Change at least this line:
PREFIX= /u

# Override default compiler and flags
CC=	gcc
CFLAGS=	-g -Wall -ansi -pedantic -O2

# You may try one of the following, if you get "wrong interpreter" errors
#LDFLAGS+=	-Wl,-no_pie
#LDFLAGS+=	-no_pie
#LDFLAGS+=	-fno_pie

# Which OS are we using (unix or plan9)?
OSDEF=	-Dunix

# Uncomment these to include the Unix extensions
EXTRA_SCM+=	-l ext/unix.scm
EXTRA_OBJS+=	unix.o
EXTRA_INIT+=	sys_init();
EXTRA_LIBS+=

# Uncomment these to include the Curses extensions
EXTRA_SCM+=	-l ext/curses.scm
EXTRA_OBJS+=	curses.o
EXTRA_INIT+=	curs_init();
EXTRA_LIBS+=	-lcurses

# Uncomment this and add REALNUM to DEFS (below) to include
# real number arithmetics
EXTRA_SCM+=	-l s9-real.scm

# Options to be added to $(DEFS)
#	-DBITS_PER_WORD_64	# use 64-bit bignum arithmetics
#	-DNO_SIGNALS		# disable POSIX signal handlers
#	-DREALNUM		# enable real number arithmetics
#				# (requires "s9-real.scm" EXTRA_SCM, above)
#	-DDEFAULT_LIBRARY_PATH="\"dir:...\""
#				# default search path for LOCATE-FILE
#	-DNETWORK		# include socket code in the Unix extension
#	-DCURSES_COLOR		# enable the CURS:SET-COLOR primitive
#	-DCURSES_RESET		# automatically run CURS:ENDWIN on the REPL
#				# (requires the Curses extension)

DEFS=	$(OSDEF) \
	-DDEFAULT_LIBRARY_PATH="\".:~/s9fes:$(LIBDIR)\"" \
	-DEXTENSIONS="$(EXTRA_INIT)" \
	-DREALNUM \
	-DNETWORK \
	-DCURSES_COLOR \
	-DCURSES_RESET

# Where to install the stuff
BINDIR=	$(PREFIX)/bin
LIBDIR=	$(PREFIX)/share/s9fes
MANDIR=	$(PREFIX)/man/man1

# Set up environment to be used during the build process
BUILD_ENV=	env S9FES_LIBRARY_PATH=.:lib:ext:contrib

default:	s9 s9.image s9.1.gz s9.1.txt lib/syntax-rules.scm \
		lib/matcher.scm

all:	default s9e

s9e:	s9e-core.image

s9:	s9.o s9.h $(EXTRA_OBJS)
	$(CC) -o s9 $(LDFLAGS) s9.o $(EXTRA_OBJS) $(EXTRA_LIBS)

s9.o:	s9.c s9-real.c s9.h
	$(CC) -o s9.o $(CFLAGS) $(DEFS) -c s9.c


s9.image:	s9 s9.scm s9-real.scm ext/unix.scm ext/curses.scm config.scm
	$(BUILD_ENV) ./s9 -i - -n $(EXTRA_SCM) -l config.scm -d s9.image

s9.1.gz:	s9.1
	sed -e "s,@LIBDIR@,$(LIBDIR)," <s9.1 |gzip -9 >s9.1.gz

unix.o:	ext/unix.c s9.h
	$(CC) $(CFLAGS) $(DEFS) -I . -o unix.o -c ext/unix.c

curses.o:	ext/curses.c s9.h
	$(CC) $(CFLAGS) $(DEFS) -I . -o curses.o -c ext/curses.c

s9e-core.image:	s9 s9.scm s9-real.scm ext/unix.scm ext/curses.scm \
		contrib/s9e.scm
	$(BUILD_ENV) ./s9 -i - -n -l ext/unix.scm -l ext/curses.scm \
		-l ext/parse-optionsb.scm -l contrib/s9e.scm \
		-d s9e-core.image

lint:
	gcc -g -Wall -ansi -pedantic s9.c && rm a.out

test:	s9 test.image
	$(BUILD_ENV) ./s9 -i test -f util/test.scm

libtest:	s9 test.image
	$(BUILD_ENV) sh util/libtest.sh

systest:	s9 test.image
	$(BUILD_ENV) ./s9 -i test -f util/systest.scm

srtest:	s9 test.image
	$(BUILD_ENV) ./s9 -i test -f util/srtest.scm

realtest:	s9 test.image
	$(BUILD_ENV) ./s9 -i test -f util/realtest.scm

test.image:	s9 s9.scm s9-real.scm
	$(BUILD_ENV) ./s9 -i - -n $(EXTRA_SCM) -d test.image

tests: test realtest srtest libtest systest

install:	install-s9 install-util

install-all:	install-s9 install-util install-s9e install-progs

# old version of install(1) may need -c
#C=-c
install-s9:	s9 s9.scm s9.image s9.1.gz
	install -d -m 0755 $(BINDIR)
	install -d -m 0755 $(LIBDIR)
	install -d -m 0755 $(LIBDIR)/help
	install -d -m 0755 $(MANDIR)
	install $C -m 0755 s9 $(BINDIR)
	strip $(BINDIR)/s9
	install $C -m 0644 s9.scm $(LIBDIR)
	install $C -m 0644 s9.image $(LIBDIR)
	install $C -m 0644 lib/* $(LIBDIR)
	install $C -m 0644 ext/*.scm $(LIBDIR)
	install $C -m 0644 contrib/* $(LIBDIR)
	install $C -m 0644 s9.1.gz $(MANDIR)
	install $C -m 0644 help/* $(LIBDIR)/help
	install $C -m 0755 util/make-help-links $(LIBDIR)
	(cd $(LIBDIR) && ./make-help-links && rm make-help-links)

install-util:
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/s9help.scm >$(BINDIR)/s9help
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/s9resolve.scm >$(BINDIR)/s9resolve
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/scm2html1.scm >$(BINDIR)/scm2html
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/scmpp.scm >$(BINDIR)/scmpp
	-chmod +x $(BINDIR)/s9help	\
		  $(BINDIR)/s9resolve	\
		  $(BINDIR)/scm2html	\
		  $(BINDIR)/scmpp

install-s9e:	s9e-core.image
	ln -fs $(BINDIR)/s9 $(BINDIR)/s9e-core
	install $C -m 0644 s9e-core.image $(LIBDIR)
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/s9e1.scm >$(BINDIR)/s9e
	-chmod +x $(BINDIR)/s9e

install-progs:
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/advgen.scm >$(BINDIR)/advgen
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/c2html1.scm >$(BINDIR)/c2html
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/cols.scm >$(BINDIR)/cols
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/dupes.scm >$(BINDIR)/dupes
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/edoc.scm >$(BINDIR)/edoc
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/htmlify.scm >$(BINDIR)/htmlify
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/s9hts.scm >$(BINDIR)/s9hts
	sed -e "s|^#! /usr/local|#! $(PREFIX)|"	\
		<prog/soccat.scm >$(BINDIR)/soccat
	-chmod +x $(BINDIR)/advgen	\
		  $(BINDIR)/c2html	\
		  $(BINDIR)/cols	\
		  $(BINDIR)/dupes	\
		  $(BINDIR)/edoc	\
		  $(BINDIR)/htmlify	\
		  $(BINDIR)/s9hts	\
		  $(BINDIR)/soccat

deinstall:	deinstall-s9 deinstall-util

deinstall-all:	deinstall-s9 deinstall-util deinstall-s9e deinstall-progs

deinstall-s9:
	rm -f $(LIBDIR)/help/* && rmdir $(LIBDIR)/help
	rm -f $(LIBDIR)/* && rmdir $(LIBDIR)
	rm -f $(BINDIR)/s9
	-rmdir $(BINDIR)
	-rmdir $(MANDIR)

deinstall-util:
	rm -f $(BINDIR)/s9help		\
	      $(BINDIR)/s9resolve	\
	      $(BINDIR)/scm2html	\
	      $(BINDIR)/scmpp

deinstall-progs:
	rm -f $(BINDIR)/advgen		\
	      $(BINDIR)/c2html		\
	      $(BINDIR)/cols		\
	      $(BINDIR)/dupes		\
	      $(BINDIR)/edoc		\
	      $(BINDIR)/htmlify		\
	      $(BINDIR)/s9hts		\
	      $(BINDIR)/soccat

deinstall-s9e:
	rm -f $(BINDIR)/s9e-core	\
	      $(LIBDIR)/s9e-core.image

tabs:
	@find . -name \*.scm -exec grep -l "	" {} \;

cd:
	./s9 -f util/check-descr.scm

clean:
	rm -f s9 s9.image s9e-core.image test.image s9.1.gz *.o *.core \
		CATEGORIES.html HACKING.html core s9fes.tgz __testfile__ 

new-version:
	vi edoc/s9.c.edoc CHANGES
	make s9.c

update-library:
	vi util/make-docs
	util/make-docs
	vi util/make-help-links \
		util/descriptions \
		util/categories.html
	clear
	@echo "Now copy the new help pages from help-new to help"
	@echo "and run util/make-help-links."

s9.1.txt:	s9.1
	cc -o rpp util/rpp.c
	nroff -mdoc s9.1 | ./rpp -a >s9.1.txt
	rm -f rpp

docs:	lib ext contrib
	util/make-docs

webdump:
	util/make-html

advdump:	prog/advgen.scm prog/adventure.adv prog/adventure.intro
	sed -e 's/@dir/quest/' -e 's/@file/index/g' <util/pagehead >pagehead
	prog/advgen.scm -rv \
		-P terminal:session \
		-p pagehead \
		-e util/pagetail \
		-i prog/adventure.intro \
		-t "The Quest for S9fES" \
		-y s9.css \
		prog/adventure.adv
	rm -f pagehead
	cp MASCOT.png advdump
	sed -e 's/^A:link/A/' -e '/^A:visited/,+3d' \
		<util/s9.css >advdump/s9.css

csums:
	txsum -u <_checksums >_checksums.new
	mv _checksums.new _checksums

mksums:	clean
	find . -type f | grep -v _checksums | txsum -m >_checksums

stripped-arc:	clean s9.1.txt
	mv Makefile Makefile.ORIG
