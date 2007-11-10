#!/bin/bash
for f in `find . -type f`| grep -v ".svn" | grep -v adress_replace.sh ;
 do
  if grep -q "\#\ 59\ Temple\ Place\ -\ Suite\ 330,\ Boston,\ MA\ 02111-1307,\ USA." $f;
  then
   cp $f $f.bak
   sed -e s/\#\ 59\ Temple\ Place\ -\ Suite\ 330,\ Boston,\ MA\ 02111-1307,\ USA./\#\ 51\ Franklin\ Street,\ Fifth\ Floor,\ Boston,\ MA\ 02110-1301,\ USA/g < $f.bak > $f 
   rm $f.bak
  fi
done
