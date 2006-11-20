(c) Holger Levsen, Oliver Osburg 2006
released under GPL2

fai-live-cd with live-package
-----------------------------

download all files in live-include-dir and run
# sudo apt-get install live-package
# sudo rm /etc/make-live.conf 	
# sudo make-live --hook live-include-dir/hook --config ./make-live.conf 



additional comments:
- this is alpha, tested with fai 3.0 on etch
- /etc/make-live.conf is not included, I basically used the package default
- feedback is great
- the live-cd works, but grub installation is buggy
- install sequence runs now in softupdate-mode. 
  This should probably be change to dirinstall or install
- base.tgz has to be taken from some FAI nfsroot.
