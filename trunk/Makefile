include VERSION

DESTDIR=$(shell pwd)/debian/tmp
DEB_HOST_ARCH=$(MACHTYPE)
DOCDIR=/usr/share/doc/fai
LIBDIR = $(DESTDIR)/usr/lib/fai
SCRIPTS = rcS_fai setup_harddisks install_packages faireboot start-stop-daemon dhclient-perl dhclient-script fcopy ftar mount2target
SBIN_SCRIPTS = make-fai-nfsroot make-fai-bootfloppy fai-setup fcopy ftar
CONFFILES= apt.conf dhclient.conf fai_modules_off

# files with variable KERNLEVERSION in it
KVERSION_FILES = $(DESTDIR)/$(DOCDIR)/templates/class/DEFAULT.var $(DESTDIR)/etc/fai.conf

all:
	$(MAKE) -C doc all

clean:
	$(MAKE) -C doc clean

veryclean: clean
	rm -f build-stamp
	dh_clean

install: 
	$(MAKE) -C doc install DOCDIR=$(DOCDIR)
	cd scripts ; install $(SBIN_SCRIPTS) $(DESTDIR)/usr/sbin
	cd scripts ; install $(SCRIPTS) $(LIBDIR)/sbin
	install -m644 lib/subroutines $(DESTDIR)/usr/share/fai
	install -m644 lib/Fai.pm $(DESTDIR)/usr/lib/perl5/Debian
	cd conf ; install -m644 $(CONFFILES) $(LIBDIR)/etc/
	install -m644 conf/fai.conf $(DESTDIR)/etc
	cp -a utils examples templates $(DESTDIR)/$(DOCDIR)
	perl -pi -e 's/_KERNELVERSION_/$(KERNELVERSION)/' $(KVERSION_FILES)
	perl -pi -e 's/FAIVERSIONSTRING/$(VERSIONSTRING)/' $(LIBDIR)/sbin/rcS_fai
	ln -fs installimage_3com $(DESTDIR)/boot/fai/bigfoot
	ln -fs installimage_3com $(DESTDIR)/boot/fai/ant01

.PHONY: clean veryclean
