#!/bin/bash

# BUGGY!
# SVG PATH      =  /home/christoph/0000_Projekte/SRV_BTSW/00_GIT/00/pages/03_030_kairus.svg
# xlink:href="#SVGID_59_"

# REMOVE SODIPODI IMAGE LINKS
# REMOVE ABSOLUTE LINKS
# REMOVE PERSONAL DATA

 XLINKID="xlink:href"
 REF=/tmp/ref${RANDOM}.tmp

    SVG=$1

  # SAVE TIMESTAMP
    touch -r $SVG $REF

    SVGPATH=`realpath $SVG | \
             rev | cut -d "/" -f 2- | rev`
    cd $SVGPATH
    SVG=`basename $SVG`
  # ------------------------------------------------------------------------- #
  # VACUUM DEFS, REMOVE SODIPODI IMG LINK, REMOVE EXPORT PATH

     inkscape --vacuum-defs $SVG
     sed -i 's/sodipodi:absref=".*"//g' $SVG
     sed -i 's/inkscape:export-filename=".*"//g' $SVG

  # ------------------------------------------------------------------------- #
  # CHANGE ABSOLUTE PATHS TO RELATIVE

    for XLINK in `cat $SVG | \
                  sed "s/$XLINKID/\n$XLINKID/g" | \
                  grep "$XLINKID"`
     do
       IMGSRC=`echo $XLINK | \
               cut -d "\"" -f 2 | \
               sed "s/$XLINKID//g" | \
               sed 's,file://,,g'`

       IMG=`basename $IMGSRC`
       IMGPATH=`realpath $IMGSRC | \
                rev | cut -d "/" -f 2- | rev`

     # http://stackoverflow.com/questions/2564634/
     # bash-convert-absolute-path-into-relative-path-given-a-current-directory
       RELATIVEPATH=`python -c \
       "import os.path; print os.path.relpath('$IMGPATH', '$SVGPATH')"`

       NEWXLINK="$XLINKID=\"$RELATIVEPATH/$IMG\""

         echo "SVG PATH      = " $SVGPATH/$SVG
         echo $XLINK
       # echo "IMG PATH      = " $IMGPATH
       # echo "RELATIVE PATH = " $RELATIVEPATH

       sed -i "s,$XLINK,$NEWXLINK,g" $SVG
    done
  # ------------------------------------------------------------------------- #

  # RESTORE TIMESTAMP
    touch -r $REF $SVG

    cd - > /dev/null


 rm $REF

exit 0;

