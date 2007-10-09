.PHONY: tidy move

DESTDIR=/srv/fai/nfsroot/live/filesystem.dir
DEST=$(DESTDIR)/usr/lib/perl/5.8

BIN   = shdd2
FILES = shdd2-commands \
	shdd2-exec \
	shdd2-fstab \
	shdd2-init \
	shdd2-lib \
	shdd2-parser \
	shdd2-sizes \
	shdd2-volumes

tidy:
	perltidy -bl -i=2 $(FILES) $(BIN)

move:
	for i in shdd2*.tdy ; do mv $$i `echo $$i | sed 's/.tdy//'` ; done

install:
	install -d $(DEST)
	install -m 444 $(FILES) $(DEST) 
	install -m 744 $(BIN) $(DESTDIR)/usr/bin
