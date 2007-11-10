#!/bin/bash
for f in `find  -type f`;
 do
  if grep -q "\#\ 59\ Temple\ Place\ -\ Suite\ 330,\ Boston,\ MA\ 02111-1307,\ USA." $f;
  then
   sed -e s/\#\ 59\ Temple\ Place\ -\ Suite\ 330,\ Boston,\ MA\ 02111-1307,\ USA./\#\ 51\ Franklin\ Street,\ Fifth\ Floor,\ Boston,\ MA\ 02110-1301,\ USA/g fai-gui/repo/svn/fai/people/kugg/bugfix_444154/
  fi
done
