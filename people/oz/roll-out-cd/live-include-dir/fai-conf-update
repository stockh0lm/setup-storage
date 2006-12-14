#! /bin/sh
# fai-conf-update
# script to update the FAI configspace based on FAI Classes.
#
# ToDo:
# - update of the package config
# - flags to change output: output in patch form.
# - tesing of installscripts with the new config on the running installserver
# 
# FixMe:
# -ugly grep after the find. 
#

FAI_CONFIGSPACE=/srv/fai/config
CLASSES=`cat /var/log/fai/localhost/last/FAI_CLASSES`
SHELLSCRIPT="/root/update_fai.sh"

if [ -f $SHELLSCRIPT ]; then
    echo "$SHELLSCRIPT exists, aborting."
    exit 1
fi

# Loop through the classes

for i in $CLASSES; do

#    Find the config files, strip off the class name in the end
#    loop through the files

    for j in `find $FAI_CONFIGSPACE/files -type f -name ".svn" -prune -o -name $i -print | grep -v \.svn`; do
	name=`echo $j | sed "s#$FAI_CONFIGSPACE/files##"| sed s/\\\/$i//`

	if [ -f $name ]; then
	    if  ! diff -q $name $j  >& /dev/null ; then
		echo "class $i needs update from $name to $j"
		echo "cp $name $j" >> $SHELLSCRIPT
	    fi
	    if [ ! -f $name ]; then
		echo file "$name is not existing on this machine, removing it from the config space"
		echo "rm $j" >> $SHELLSCRIPT
	    fi
	fi
    done
done

echo "review the results in $SHELLSCRIPT and run it to actually update the FAI config space."
