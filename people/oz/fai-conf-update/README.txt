fai-conf-update

For what?

This script is useful in a situation when you have to move the FAI 
server to new hardware. Just call this script, and changes in /etc on 
the install server will be transferred to the FAI config-space.

when you run fai-cd (currently broken) or h01gers fai-live, this updated 
config space is used for the installation with the CD. Thus, one can 
save much time in moving servers to new hardware, as all services are 
re-installed automatically.

In most cases, the installation should work as on the old box. In the 
case of needed tweaks the hardware - just run this script again 
on the *new* server, and burn the image on CD until all errors are 
fixed, mostly one run should be sufficient.

I'd call it: "Server Evolution". :-)


Bugs, limitations:

- This script is very alpha. 
- It would also be nice to update the 
  packages list in the config-space. 
- Nice: pre-check of the config-space with failint!
