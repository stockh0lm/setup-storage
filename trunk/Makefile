include VERSION

DESTDIR=$(shell pwd)/debian/tmp
DEB_HOST_ARCH=$(MACHTYPE)
DOCDIR=/usr/share/doc/fai
LIBDIR = $(DESTDIR)/usr/lib/fai
SCRIPTS = rcS_fai setup_harddisks install_packages faireboot start-stop-daemon dhclient-perl dhclient-script
SBIN_SCRIPTS = mk3comimage make-fai-nfsroot make-fai-bootfloppy
CONFFILES= apt.conf apt.conf.nfsroot dhclient.conf

# files with variable KERNLEVERSION in it
KVERSION_FILES = $(DESTDIR)/$(DOCDIR)/templates/package_config/KERNEL_SOFT $(DESTDIR)/$(DOCDIR)/templates/class/S91global.source $(DESTDIR)/$(DOCDIR)/templates/class/S98variables.source

all:
	$(MAKE) -C kernel kernels

veryclean: clean
	$(MAKE) -C kernel veryclean

clean:
	$(MAKE) -C kernel clean
	rm -f /tmp/make.log

install: 
	$(MAKE) -C kernel install LIBDIR=$(LIBDIR)
	cd scripts ; install $(SBIN_SCRIPTS) $(DESTDIR)/usr/sbin
	cd scripts ; install $(SCRIPTS) $(LIBDIR)/sbin
	install -m644 lib/subroutines $(DESTDIR)/usr/share/fai
	install -m644 lib/Fai.pm $(DESTDIR)/usr/lib/perl5/Debian
	cd conf ; install -m644 $(CONFFILES) $(LIBDIR)/etc/
	install -m644 conf/fai.conf $(DESTDIR)/etc
	cp -dRp examples templates doc/* $(DESTDIR)/$(DOCDIR)
	perl -pi -e 's/KERNELVERSION/$(KERNELVERSION)/' $(KVERSION_FILES)
	perl -pi -e 's/FAIVERSIONSTRING/$(VERSIONSTRING)/' $(LIBDIR)/sbin/rcS_fai
	ln -fs installimage $(DESTDIR)/boot/fai/faiserver
	ln -fs installimage $(DESTDIR)/boot/fai/faiclient01

.PHONY: clean veryclean
