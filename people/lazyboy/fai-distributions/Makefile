include VERSION

PACKAGENAME = fai-distributions

DESTDIR=$(shell pwd)/debian/tmp
LIBDIR = $(DESTDIR)/usr/lib/$(PACKAGENAME)

DOCDIR = $(DESTDIR)/usr/share/doc/$(PACKAGENAME)

VARLIBDIR = $(DESTDIR)/var/lib/$(PACKAGENAME)

BINDIR = $(DESTDIR)/usr/bin
CONFDIR = $(DESTDIR)/etc/$(PACKAGENAME)/
SBINDIR = $(DESTDIR)/usr/sbin
LIBDIR = $(DESTDIR)/usr/lib/$(PACKAGENAME)

all:
	$(MAKE) install

clean:
	find -name svn-commit.tmp -o -name svn-commit.tmp~ | xargs -r rm

veryclean: clean
	$(MAKE) -f debian/rules clean

install: 
	mkdir -p $(BINDIR) $(CONFDIR) $(SBINDIR) $(LIBDIR)
	mkdir -p $(VARLIBDIR) $(DOCDIR)
	# FIXME: we should have manpages and they should be installed here
	#install man/* $(DESTDIR)/man
	#cd bin ; install * $(DESTDIR)/usr/bin
	cp -a classes $(DOCDIR)
	cp -a dists/* $(LIBDIR)
	cp -a sbin/* $(SBINDIR)

	# FIXME: those links don't work anyway... fix then re-enable the links
	#for dist in `ls dists`; do \
		ln -s /usr/lib/$(PACKAGENAME)/$$dist/make-base-tgz $(DESTDIR)/usr/sbin/make-$$dist-base-tgz; \
		chmod +x $(DESTDIR)/usr/sbin/make-$$dist-base-tgz; \
	#done
	install etc/* $(CONFDIR)

.PHONY: clean veryclean
