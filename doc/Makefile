# CLISP Implementation Notes generation
# (C) 2000-2011 Sam Steingold
# (C) 2024 Bruno Haible

# To generate HTML, you will need xsltproc & xmllint from the libxml2
# (http://xmlsoft.org/) package in addition to the DocBook DTDs and XSL
# stylesheets (http://www.docbook.org/)
# When writing docbook documentation, you need the "DocBook Definitive Guide"
# http://docbook.org/tdg/en/html/docbook-x.html

# which DTD to validate against
DTDVER=4.5

# all included XML files
IMPNOTES=cl-ent.xml clhs-ent.xml impbody.xml impent.xml mop.xml gray.xml     \
	impext.xml impissue.xml impbyte.xml unix-ent.xml mop-ent.xml faq.xml \
	history.xml fdl-1.3.dbk gpl-2.0.dbk \
	../modules/asdf/asdf.xml	        \
	../modules/berkeley-db/berkeley-db.xml	\
	../modules/berkeley-db/ent-bdb.xml	\
	../modules/dbus/dbus.xml		\
	../modules/dirkey/dirkey.xml		\
	../modules/fastcgi/fastcgi.xml		\
	../modules/gdbm/gdbm.xml		\
	../modules/gtk2/gtk.xml			\
	../modules/i18n/i18n.xml		\
	../modules/libsvm/svm.xml		\
	../modules/matlab/matlab.xml		\
	../modules/netica/netica.xml		\
	../modules/oracle/oracle.xml		\
	../modules/pari/pari.xml		\
	../modules/pcre/pcre.xml		\
	../modules/postgresql/postgresql.xml	\
	../modules/rawsock/rawsock.xml		\
	../modules/readline/readline.xml	\
	../modules/regexp/regexp.xml		\
	../modules/syscalls/syscalls.xml	\
	../modules/zlib/zlib.xml
# all used stylesheets
CLISP_XSL = chunk.xsl common.xsl fo.xsl id-href-map.xsl man.xsl pile.xsl
CLISP_CSS = impnotes.css
# targets for <olink> resolution
OLINK = man.tdb clink.tdb pile.tdb chunk.tdb olink-pile.xml olink-chunk.xml

RM=/bin/rm -f
CURDIR=$(shell pwd)

# what to do when there is no local system-wide DTD & XSL?
DOWNLOAD=yes

ifneq (,$(filter Windows%,$(OS)))
DTD_PATH=$(firstword $(wildcard ./docbook-dtd*/docbookx.dtd \
	/usr/share/docbook-xml$(DTDVER)/docbookx.dtd))
# Make sure to use a trailing slash.
XSL_PATH=$(firstword $(wildcard ./docbook-xsl*/ \
	/usr/share/docbook-xsl*/))
FOP=/cygdrive/c/java/fop-0.20.5/fop.bat
else
DTD_PATH=$(firstword $(wildcard ./docbook-dtd*/docbookx.dtd \
	/usr/share/sgml/docbook/xml-dtd-$(DTDVER)*/docbookx.dtd \
	/usr/share/xml/docbook/schema/dtd/$(DTDVER)*/docbookx.dtd))
XSL_PATH=$(firstword $(wildcard ./docbook-xsl*/ \
	/usr/share/sgml/docbook/xsl-stylesheets-1*/ \
	/usr/share/xml/docbook/stylesheet/nwalsh*/))
FOP=../../../fop/fop
endif

IN_FILES = impnotes.xml clisp.xml clisp-link.xml
# common dependencies for all checkers
CHECK_DEPS = $(IN_FILES)
ifeq (,$(wildcard $(DTD_PATH))) # DTD does not exist
ifeq (yes,$(DOWNLOAD))		# download once
CHECK_DEPS += docbook-dtd
DTD_PATH=./docbook-dtd/docbookx.dtd
else # download on each check (you need network-aware tools to use it)
# this is the original DTD
DTD_PATH=http://www.oasis-open.org/docbook/xml/$(DTDVER)/docbookx.dtd
#DTD_PATH=http://www.docbook.org/xml/$(DTDVER)/docbookx.dtd
endif
endif

# common dependencies for all generators
GEN_DEPS = common.xsl
ifeq (,$(wildcard $(XSL_PATH))) # stylesheets do not exist
ifeq (yes,$(DOWNLOAD))	        # download once
GEN_DEPS += docbook-xsl
XSL_PATH=./docbook-xsl/
else # download on each build (you need network-aware tools to use it)
XSL_PATH=http://docbook.xml-doc.org/snapshots/xsl/
# XSL_PATH=http://docbook.sourceforge.net/release/xsl/snapshot/
# XSL_PATH=http://docbook.sourceforge.net/release/xsl/current/
endif
endif

# The xmlcatalog utility (from libxml2)
XMLCATALOG=xmlcatalog

# chose one:
#TEXI2HTML=texi2html -monolithic -verbose $< -out_file $@
TEXI2HTML=makeinfo --verbose --no-split --no-headers --force --html $< -o $@

# NB: keep in sync with src/makemake.in:MYIMPROOT
DIST_SFBETA = sds,clisp@web.sf.net:/home/groups/c/cl/clisp/htdocs/beta
DIST =
RSYNC = rsync -avC --copy-unsafe-links
CHMOD = chmod -R a+rX

##### nothing user-serviceable below #####

# name of XML catalog file to create
# (if not specified, no local catalog created or used)
CATALOG_FILE=catalog.xml

# Stylesheets URI used internally in the CLISP project *.xsl files.
XSL_URI=http://docbook.sourceforge.net/release/xsl/current/

FILLIN=. ../version.sh && sed -e 's,@DTD@,$(DTD_PATH),' \
	    -e 's,@DTDVER@,$(DTDVER),' \
	    -e 's,@VERSION@,'$${VERSION_NUMBER}',' \
	    -e 's,@TODAY@,'`date +"%Y-%m-%d"`','

# cannot use profiling <http://www.sagehill.net/docbookxsl/Profiling.html>
# because that would require XSL tools to be installed on user machine
SGML_UNCOMMENT=-e 's/^<!--\#\(.*\)-->$$/\#\1/'

E=\ *<!--\(\#[^-]*\)--> *
ROFF_UNCOMMENT=-e 's/^$E$$/\1/' -e 's/$E$$/\n\1/' -e 's/^$E/\1\n/' -e 's/$E/\n\1\n/g'

.PHONY : all up count search clean

all: check impnotes.html regexp.html man

ifneq (,$(CATALOG_FILE))
# depends on Makefile because of $(XSL_PATH)
# gnu license xml files specify a bad dtd file
GNU_DTD = http://www.oasis-open.org/docbook/xml/$(DTDVER)/docbookx.dtd
$(CATALOG_FILE): Makefile
	$(RM) $(CATALOG_FILE)
	$(XMLCATALOG) --create > $(CATALOG_FILE)
	$(XMLCATALOG) --noout --add "rewriteURI" \
		$(XSL_URI) $(XSL_PATH) $(CATALOG_FILE)
	$(XMLCATALOG) --noout --add "rewriteSystem" \
		$(XSL_URI) $(XSL_PATH) $(CATALOG_FILE)
	$(XMLCATALOG) --noout --add "rewriteURI" \
		$(GNU_DTD) $(DTD_PATH) $(CATALOG_FILE)
XSLTPROC=XML_CATALOG_FILES="$(CATALOG_FILE) ${XML_CATALOG_FILES}" xsltproc
else
XSLTPROC=xsltproc
endif
XMLS_COMMON = --timing --xinclude

# target.database.document in this command is a workaround for bug
#   warning: failed to load external entity \"olinkdb.xml\"
#   Olink error: could not open target database \'olinkdb.xml\'.
# https://sourceforge.net/p/docbook/bugs/1111/
MAKE_TDB=$(XSLTPROC) $(XMLS_COMMON) --stringparam collect.xref.targets "only" \
  --stringparam target.database.document "olink-pile.xml" \
	--stringparam targets.filename

man.tdb: clisp.xml pile.xsl $(GEN_DEPS) $(CATALOG_FILE)
	$(MAKE_TDB) "$@" pile.xsl $<

clink.tdb: clisp-link.xml pile.xsl $(GEN_DEPS) $(CATALOG_FILE)
	$(MAKE_TDB) "$@" pile.xsl $<

pile.tdb: impnotes.xml $(IMPNOTES) pile.xsl $(GEN_DEPS) $(CATALOG_FILE)
	$(MAKE_TDB) "$@" pile.xsl $<

chunk.tdb: impnotes.xml $(IMPNOTES) chunk.xsl $(GEN_DEPS) $(CATALOG_FILE)
	$(MAKE_TDB) "$@" chunk.xsl $<

ifneq (,$(wildcard ../version.sh))
clisp.xml: clisp.xml.in ../version.sh Makefile
	$(RM) $@
	$(FILLIN) $< > $@

clisp-link.xml: clisp-link.xml.in ../version.sh Makefile
	$(RM) $@
	$(FILLIN) $< > $@

impnotes.xml: impnotes.xml.in $(IMPNOTES) ../version.sh Makefile
	$(RM) $@
	$(FILLIN) $< > $@
endif

XMLOUT=$(XSLTPROC) $(XMLS_COMMON) --stringparam target.database.document
DOC_MAN = --stringparam current.docid "man"
DOC_CLK = --stringparam current.docid "clink"
DOC_IMP = --stringparam current.docid "impnotes"

# Post-processing of man.xsl output.
# Add a newline before .PP, see
# <https://sourceforge.net/p/clisp/bugs/748/>
# <https://bugs.launchpad.net/ubuntu/+source/clisp/+bug/2022970>
# <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1041788>
# Replace old 'an-trap' with newer 'an-input-trap' (no visible effect), see
# <https://savannah.gnu.org/bugs/?61002>.
MAN_XSL_POSTPROCESS = sed -i -e 's/\(.\)\.PP/\1\n.PP/g' -e 's/an-trap/an-input-trap/'

CHECK_IDS = if egrep -Hnr 'id="id[0-9]*"' $@; then exit 1; else true; fi

clisp.html: clisp.xml $(GEN_DEPS) pile.xsl $(OLINK)
	$(XMLOUT) "olink-pile.xml" $(DOC_MAN) -o $@ pile.xsl $<
	$(CHECK_IDS)

clisp.1: clisp.xml $(GEN_DEPS) man.xsl $(OLINK)
	$(XMLOUT) "olink-pile.xml" $(DOC_MAN) -o $@ man.xsl $<
	$(MAN_XSL_POSTPROCESS) $@

clisp-link.html: clisp-link.xml $(GEN_DEPS) pile.xsl $(OLINK)
	$(XMLOUT) "olink-pile.xml" $(DOC_CLK) -o $@ pile.xsl $<
	$(CHECK_IDS)

clisp-link.1: clisp-link.xml $(GEN_DEPS) man.xsl $(OLINK)
	$(XMLOUT) "olink-pile.xml" $(DOC_CLK) -o $@ man.xsl $<
	$(MAN_XSL_POSTPROCESS) $@

# Generates _clisp.html from clisp.html.
# For quality checking of _clisp.html, use "make -f Makefile.devel view-html".
_%.html: %.html
	sed $(SGML_UNCOMMENT) $< > $@

# Generates _clisp.1 from clisp.1.
# For quality checking of _clisp.1, use "make -f Makefile.devel view-man"
# or "groff -man -Tutf8 _clisp.1 | less -R".
_%.1: %.1
	sed $(ROFF_UNCOMMENT) $< > $@

check: $(IMPNOTES) $(CHECK_DEPS)
	for f in $(IN_FILES); do \
	  xmllint $(XMLS_COMMON) --noout --postvalid --noent $$f; done

impnotes.texi: impnotes.xml $(IMPNOTES)
	time docbook2texi $<

impnotes.html: impnotes.xml $(IMPNOTES) $(GEN_DEPS) pile.xsl $(OLINK)
	$(XMLOUT) "olink-pile.xml" $(DOC_IMP) -o $@ pile.xsl $<
#	cp impnotes.html impnotes-saved.html
#	tidy -config tidy.conf -f tidy.err impnotes.html || true
	$(CHECK_IDS)
	(test -n "$(DIST)" && $(CHMOD) impnotes.html impnotes.css && \
	 $(RSYNC) impnotes.html impnotes.css $(DIST)/) || true

man: _clisp.html _clisp.1 _clisp-link.html _clisp-link.1
	(cd ../build && make clisp.html clisp.1 && \
	 $(CHMOD) clisp.1 clisp.html && \
	 test -n "$(DIST)" && $(RSYNC) clisp.1 clisp.html $(DIST)/) || true

impnotes.fo: impnotes.xml $(IMPNOTES) fo.xsl $(XSL_TARGET)
	$(XMLOUT) "olink-pile.xml" $(DOC_IMP) -o $@ fo.xsl $<

# http://xmlgraphics.apache.org/fop/
impnotes.pdf: impnotes.fo
	${FOP} $< $@

id-href.map : chunk.tdb
	$(XSLTPROC) $(XMLS_COMMON) -o $@ id-href-map.xsl $<

html: impnotes.xml $(IMPNOTES) $(GEN_DEPS) chunk.xsl pile.xsl clisp.xml $(OLINK) id-href.map
	if [ ! -h $@ ]; then $(RM) -r $@; \
	  if [ -d ../../sf/www/impnotes ]; then ln -s ../../sf/www/impnotes $@; \
	  elif [ -d ../../www/impnotes ]; then ln -s ../../www/impnotes $@; \
	  else echo 'no sf/www dir'; false; fi; fi
	cd $@/ && grep -v -e "^#" .symlinks | sed 's/^/ln -vf /' | sh -
	cp -pv impnotes.css id-href.map $@/
	$(XMLOUT) "olink-chunk.xml" $(DOC_IMP) -o $@/ chunk.xsl $<
	$(XMLOUT) "olink-chunk.xml" $(DOC_MAN) -o $@/clisp.html pile.xsl clisp.xml
	$(XMLOUT) "olink-chunk.xml" $(DOC_CLK) -o $@/clisp-link.html pile.xsl clisp-link.xml
	sed $(SGML_UNCOMMENT) $@/clisp.html > _clisp-1.html
	sed $(SGML_UNCOMMENT) $@/clisp-link.html > _clisp-link-1.html
	cd ../build; make clisp-1.html clisp-link-1.html;
	mv -f ../build/clisp-1.html $@/clisp.html
	mv -f ../build/clisp-link-1.html $@/clisp-link.html
	rm -f _clisp-1.html _clisp-link-1.html
	$(CHECK_IDS)
	cd html; cd ..; $(CURDIR)/../utils/fix-perms.sh
	(test -n "$(DIST)" && $(CHMOD) $@ impnotes.css && \
	 $(RSYNC) $@/*.html $@/id-href.map impnotes.css $(DIST)/impnotes/) \
	|| true

# try to use http://www.graphviz.org/ instead of openoffice for MOP
# class inheritance diagrams
mop-classes.png : mop-classes.dot
	dot -Tpng mop-classes.dot -o mop-classes.png

up: impnotes.html html
	mv html impnotes
	$(CHMOD) impnotes.html impnotes
	$(RSYNC) impnotes.html impnotes $(DIST_SFBETA)
	mv impnotes html

regexp.html: ../modules/regexp/regexp.texinfo
	$(TEXI2HTML)

clean: force
	$(RM) impnotes.texi impnotes.html impnotes.pdf html \
	  clisp.html clisp.1 *.tdb $(CATALOG_FILE) impnotes.fo \
	  id-href.map clisp-link.html clisp-link.1
	test -f impnotes.xml.in && $(RM) impnotes.xml
	test -f clisp.xml.in && $(RM) clisp.xml
	test -f clisp-link.xml.in && $(RM) clisp-link.xml

count: $(IMPNOTES)
	wc $^

DTD_DOWNLOAD=http://www.docbook.org/xml/$(DTDVER)/docbook-xml-$(DTDVER).zip
docbook-dtd :
	mkdir docbook-dtd && cd docbook-dtd && \
	  wget -O docbook-xml.zip $(DTD_DOWNLOAD) && \
	  unzip docbook-xml.zip && $(RM) docbook-xml.zip

#XSL_DOWNLOAD=https://sourceforge.net/projects/docbook/files/latest/download?source=files
XSL_VERSION=1.79.1
XSL_DOWNLOAD=https://downloads.sourceforge.net/project/docbook/docbook-xsl/$(XSL_VERSION)/docbook-xsl-$(XSL_VERSION).zip
docbook-xsl :
	wget $(XSL_DOWNLOAD) && unzip docbook-xsl-$(XSL_VERSION).zip && \
	  mv -v docbook-xsl-$(XSL_VERSION) docbook-xsl && \
	  $(RM) docbook-xsl-$(XSL_VERSION).zip
	grep '<fm:Version>' docbook-xsl/VERSION

IMPNOTES_SRC = impnotes-src
$(IMPNOTES_SRC).zip : Makefile impnotes.xml clisp.xml clisp-link.xml \
		$(IMPNOTES) $(CLISP_XSL) $(CLISP_CSS)
	$(RM) -r $@ $(IMPNOTES_SRC)
	mkdir $(IMPNOTES_SRC);
	for f in $^; do sed 's,\.\./modules/[^/]*/,,' $$f > $(IMPNOTES_SRC)/`basename $$f`; done
	zip -9mvr $@ $(IMPNOTES_SRC)
	(test -n "$(DIST)" && $(CHMOD) $@ ../src/NEWS && \
	 $(RSYNC) $@ ../src/NEWS $(DIST)/) || true

SEARCH=
search: force
	@if test -z "$(SEARCH)"; then echo "usage: make search SEARCH=string"; \
	else grep -n -- '$(SEARCH)' $(IMPNOTES) $(addsuffix .in, $(IN_FILES)); fi

force:
