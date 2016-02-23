#!/bin/bash

 PDF=BTSW_160130.pdf

 gs -o - -sDEVICE=inkcov $PDF > tmp.inkcov

 IFS=$'\n' 
 for PAGE in `cat tmp.inkcov | grep "^Page"`
  do
     CMYK=`grep -A 1 "^${PAGE}$" tmp.inkcov | #
           tail -n 1`

     PAGECOLOR="" # RESET
     for CMY in `echo $CMYK | sed 's/ /\n/g' | #
                 sed '/^$/d' | head -n 3     | #
                 sed 's/\.//g'`
      do
         if [ $CMY -gt 0 ]; then
              PAGECOLOR="$PAGE HAS COLOR ($CMYK)"
         fi
     done

          if [ `echo $PAGECOLOR | wc -c ` -gt 1 ]; then
                echo $PAGECOLOR
          fi
 done

exit 0;

