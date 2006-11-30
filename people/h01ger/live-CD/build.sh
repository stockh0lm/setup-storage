#!/bin/sh
#
# (c) 2006 Holger Levsen <debian@layer-acht.org>
# Licended under GPL2
#
#
# build script for fai live-cd
#
##############################################################################

#
# only build in ~/live-CD
#
cd
BUILD_DIR="live-CD"
if [ ! -d $BUILD_DIR ] ; then
	echo "`pwd`$BUILD_DIR doesn't exist, aborting."
	echo
	echo "cd && svn co svn://svn.debian.org/svn/fai/people/h01ger/live-CD ./live-CD"
	exit 1
fi

PUBLISH_DIR="/www/webserver/faicd.debian.net/htdocs/"
LOCKFILE="/var/lock/failive-build"
LOGFILE=`mktemp`
TODAY="`date +%Y%m%d%H%M`"

#
# check lockfile
#
if [ -f "$LOCKFILE" ] ; then
	echo $LOCKFILE exists, aborting
	exit 1
fi
touch $LOCKFILE

#
# cleanup & prepare
#
cd $BUILD_DIR 
sudo rm debian-live -rf
[ $? ] || echo "problems removing old build"
# display diffs from current local version to version in repository
svn diff --revision HEAD
# update to version in repository
svn up

#
# build
#
nice sudo /usr/sbin/make-live --hook live-include-dir/hook --config make-live.conf > $LOGFILE 2>&1

#
# publish
# 
if [ -f debian-live/binary.iso ] ; then
  cp debian-live/binary.iso $PUBLISH_DIR/faicd-${TODAY}.iso
else 
  echo "#########################################################"
  echo 
  echo "An error occured, .iso was not created :-("
  echo 
fi 
cp $LOGFILE $PUBLISH_DIR/faicd-${TODAY}.log
chmod 644 $PUBLISH_DIR/faicd-${TODAY}.log
rm $LOGFILE

#
# cleanup lockfile
#
rm $LOCKFILE

#
# cleanup old images and logs
# todo: enable rm for real
#
cd $PUBLISH_DIR
find . -mtime +1 !  -name "fai*-*00.???" -exec echo rm {} \;
find . -mtime +2 !  -name "fai*-1600.???" -exec echo rm {} \;
find . -mtime +14 ! -name "fai*-0400.???" -exec echo rm {} \;

