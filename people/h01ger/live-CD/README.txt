(c) Holger Levsen, Oliver Osburg 2006
released under GPL2

fai-live-cd with live-package
-----------------------------

aim
---

The aim of this fai-live-cd is to replace the old fai-cd with a cd build with 
modern tools. A fai-cd boots a system, and then runs FAI on it, to install that
system. So, as opposed to normal live-cds, a fai-cd destroys an existing 
installation and installs the machine.

Currently it only installs a basic debian system, in future one should be able 
to select (via syslinux kernel params) the type of installation, i.e. normal,
fai-server or desktop.

But first, this should be a proof of concept and install a basic debian system.


howto
-----

download all files in live-include-dir and run
# sudo apt-get install live-package
# sudo rm /etc/make-live.conf 	
# sudo make-live --hook live-include-dir/hook --config ./make-live.conf 


additional comments:
--------------------

- this is alpha, tested with fai 3.0 on etch
- /etc/make-live.conf is not included, I basically used the package default
- feedback is great
- the live-cd works, but grub installation is buggy
- install sequence runs now in softupdate-mode. 
  This should probably be change to dirinstall or install
- FIX NEEDED: /etc/fstab has to be copied from $LOGDIR (wherever that 
  is)
