(c) Oliver Osburg 2006
released under GPL2


* Features:

Installs an Debian/GNU Linux box running etch with the following 
configured packages:

** Mediawiki 1.7
** OpenLDAP Server
** LAM (LDAP account Manager)
** FAI (installs LDAP Clients for the installed system. Home are _not_ 
  mounted via NFS, but authentification is centralized via LDAP
** entire install infrastructure
** the script "fai-conf-update" is included to enable automatic config 
  space upgrades
** Clients are installed with a FreeDOS partition. using the partimage 
   approach you can install any OS you wish via FAI. 


Thus, one should be able to install a Pool from 10-100 Clients within
one day. Software should meat the average needs and can be easyly
extended. The FreeDOS Image can be replaced with a Sysprep'ed Win2000/XP Image. You need a DVD to boot then.

Use the script "update-fai-config" to update the config space of your
server, and "make-live" to build an install CD. Can be used to move
the Server to new hardware.


! FreeDOS included !

for source code and more info:

http://www

fai roll-out-cd with live-package
-----------------------------

* Usage:

download all files in live-include-dir and run
# sudo apt-get install live-package
# sudo rm /etc/make-live.conf 	
# sudo make-live --hook live-include-dir/hook --config ./make-live.conf 


* additional comments:

** this is alpha, tested with fai 3.0 on etch
** /etc/make-live.conf is not included, I basically used the package 
   default
** If you use this at home with limited bandwidth, use "approx"!

Questions, comments and cookies: osburg@osburg.org

