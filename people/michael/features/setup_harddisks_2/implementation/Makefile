DESTDIR=/srv/fai/nfsroot/live/filesystem.dir
DEST=$(DESTDIR)/usr/lib/perl/5.8

BIN   = shdd2
FILES = shdd2-commands \
	shdd2-exec \
	shdd2-fstab \
	shdd2-init \
	shdd2-parser \
	shdd2-sizes \
	shdd2-volumes

install:
	install -d $(DEST)
	install -m 444 $(FILES) $(DEST) 
	install -m 744 $(BIN) $(DESTDIR)/usr/bin


# TODO (bessere) fehlermeldungen wenn parted oder mdadm oder lvm tools streiken
# 23:10 <MT> bzw. man müsste mal sehen, was man tun muss, damit vgdisplay die sehen kann
# 23:10 <MT> ich muss jetzt offline gehen, aber vielleicht kannst Du mal versuchen, das zu debuggen
# 23:10 <stockholm> ich werde es versuche.
# 23:10 <MT> oder eben die dd/hdparm sachen einfach reinbauen
# 23:10 <stockholm> ja, das werde ich erst machen
# 23:11 <stockholm> damit ich weiter komme
# 23:11 <MT> klar
# 23:11 <MT> falls Du dann Zeit zum debuggen hast, solltest vielleicht eher noch in shdd2-volumes reinschauen
# 23:12 <MT> get_current_lvm
# 23:12 <MT> _da_ sollte er eigentlich die alten Sachen finden

#!/bin/sh
#clean drives, BAD BAD HAX wipe the drive before lvm is loaded. 
#dd if=/dev/zero of=/dev/sda2 bs=1k count=1
#dd if=/dev/zero of=/dev/sda1 bs=1k count=1
#dd if=/dev/zero of=/dev/sda bs=1k count=1
#hdparm -z /dev/sda

#modprobe dm_mod



