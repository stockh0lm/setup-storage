#!/bin/sh
files="confdir.gif defclass.gif partition.gif extrbase.gif debconf.gif instsoft.gif configure.gif savelog.gif faiend.gif"
for file in $files;
do cp $1 $file;
done
