# This script is part of FAI (Fully Automatic Installation)
# (c) 2003-2004 by Thomas Lange, lange@informatik.uni-koeln.de
# Universitaet zu Koeln

SRCDIR = ../
include ../VERSION

DESTDIR=/tmp/jumpstart
# $(shell pwd)/debian/fai

SCRIPTS = fcopy ftar fai-class fai-do-scripts
LIBS = fai-savelog
SHARES = subroutines subroutines-sunos
FAI=$(DESTDIR)/fai

tar: install
	tar -C $(DESTDIR) -cvf - . | gzip > /tmp/fai-solaris.tar.gz 

install: 
	rm -rf $(DESTDIR)
	mkdir -p $(FAI) $(DESTDIR)/lib $(DESTDIR)/hooks
	cp -a README.sunos bin $(DESTDIR)
	cp -a class disk_config package_config scripts files $(FAI)
	cd ../scripts ; install $(SCRIPTS) $(DESTDIR)/bin
	cd ../lib ;     install $(LIBS) $(DESTDIR)/bin
	cd ../share   ; install $(SHARES) $(DESTDIR)/bin
	cd ../examples/simple/class ; cp 01alias $(FAI)/class


	chmod -R a+rx $(DESTDIR)/bin $(FAI)/scripts
	perl -pi -e 's/FAIVERSIONSTRING/$(VERSIONSTRING)/' $(DESTDIR)/bin/subroutines-sunos
	find $(DESTDIR) -name CVS | xargs rm -rf

clean:
	rm -rf $(DESTDIR)

.PHONY: clean veryclean install
