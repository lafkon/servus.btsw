#!/bin/bash

# =========================================================================== #
# THIS IS A FRAGILE SYSTEM, HANDLE WITH CARE.                                #
# =========================================================================== #

  MAIN="Behind_The_Smart_World.mdsh"
  HTML="__/preepub.html"

# --------------------------------------------------------------------------- #
# INTERACTIVE CHECKS (DISABLE IF YOU KNOW WHAT YOU'RE DOING ;))
# --------------------------------------------------------------------------- #
  clear
  if [ ! -f $MAIN ] ||
     [ `echo "$HTML" | wc -c` -lt 2 ] ||
     [ `echo "$HTML" | grep ".html$" | wc -l` -lt 1 ] ||
     [ `echo "$MAIN" | wc -c` -lt 2 ]
   then echo; echo "Define input and output file, please!"
              echo "e.g. $0 input.mdsh output.html"; echo
      exit 0;
  fi

# if [ -f $HTML ]; then
#      echo "$HTML does exist"
#      read -p "overwrite $HTML? [y/n] " ANSWER
#      if [ X$ANSWER != Xy ] ; then echo "BYE BYE!"; exit 1; fi
# else
#      touch $HTML
# fi

#  HTMLBASE=`realpath $HTML | rev | cut -d "/" -f 2- | rev`
#  HTMLSRCDIRNAME="_"
#  HTMLSRCDIR="$HTMLBASE/$HTMLSRCDIRNAME"
# if [ ! -d $HTMLSRCDIR ]; then
#      echo
#      echo "$HTMLSRCDIR does not exist"
#      read -p "create $HTMLSRCDIR? [y/n] " ANSWER
#      if [ X$ANSWER == Xy ] ; then 
#      echo "creating $HTMLSRCDIR"; mkdir $HTMLSRCDIR
#      else echo "BYE BYE!"; exit 1; fi
# fi
# --------------------------------------------------------------------------- #



# --------------------------------------------------------------------------- #

  TMPDIR=. ;  TMPID=$TMPDIR/TMP`date +%Y%m%H``echo $RANDOM | cut -c 1-4`

  SRCDUMP=${TMPID}.maindump

  REFURL="http://freeze.sh/etherpad/export/_/references.bib"

  HEADMARK="= FROM MDSH START ="
  FOOTMARK="= FROM MDSH END ="
  SELECTLINES="tee"    # OBSOLETE ?

# =========================================================================== #
# CONFIGURATION                                                               #
# --------------------------------------------------------------------------- #


# INCLUDE/COMBINE FUNCTIONS
# --------------------------------------------------------------------------- #
  FUNCTIONSBASIC=lib/sh/201602_basic.functions
   FUNCTIONSPLUS=lib/sh/160223_epub.functions
       FUNCTIONS=$TMPID.functions
  cat $FUNCTIONSBASIC $FUNCTIONSPLUS > $FUNCTIONS
  source $FUNCTIONS

# =========================================================================== #
# DEFINITIONS SPECIFIC TO OUTPUT
# --------------------------------------------------------------------------- #
  PANDOCACTION="pandoc --ascii -r markdown -w html"
# --------------------------------------------------------------------------- #
# FOOTNOTES [^]{the end is near, the text is here}
# ---------
  FOOTNOTEOPEN="FOOTNOTEOPEN$RANDOM{" ; FOOTNOTECLOSE="}FOOTNOTECLOSE$RANDOM"
# --------------------------------------------------------------------------- #
# CITATIONS [@xx:0000:aa] / [@[p.44]xx:0000:aa]
# ---------
  CITEOPEN="CITEOPEN$RANDOM" ; CITECLOSE="CITECLOSE$RANDOM"
  CITEPOPEN="$CITEOPEN" ; CITEPCLOSE="CITEPCLOSE$RANDOM"
# --------------------------------------------------------------------------- #
# COMMENT
# -------
  COMSTART='<!--'; COMCLOSE='-->'
# =========================================================================== #


# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# --------------------------------------------------------------------------- #
# ACTION STARTS HERE!
# --------------------------------------------------------------------------- #
  mdsh2src $MAIN


# --------------------------------------------------------------------------- #
# PROCESS ALL HTML
# --------------------------------------------------------------------------- #
# http://tidy.sourceforge.net/docs/quickref.html#show-body-only 
  echo "show-body-only: y"     >  tc.txt
  echo "wrap-attributes: n"    >> tc.txt
  echo "quiet:y"               >> tc.txt
  echo "vertical-space:y"      >> tc.txt

# COPY MAINHTML TO MATCH SRCDUMP (AS SPLITDUMPS DO)
 #MAINHTML="$HTML"
 #cp $HTML `echo $SRCDUMP | sed 's/\.[a-z]*$/.html/'`

# GET REFERENCE FILE
  BIBTMP=${TMPID}.bibtmp
# wget --no-check-certificate \
#      -q -O - $REFURL     | #
# sed 's/@movie/@misc/g'   | #
# bib2xml                  | #
# sed ":a;N;\$!ba;s/\n//g" | #
# sed 's/>[ ]*</></g'      | #
# sed 's/<mods /\n&/g'     | #
# sed 's/<\/mods>/&\n/g'   | #
# tee > $BIBTMP

  cat JUNK/references.bib  | #
  sed 's/@movie/@misc/g'   | #
  bib2xml                  | #
  sed ":a;N;\$!ba;s/\n//g" | #
  sed 's/>[ ]*</></g'      | #
  sed 's/<mods /\n&/g'     | #
  sed 's/<\/mods>/&\n/g'   | #
  tee > $BIBTMP

 #touch ${TMPID}.splitlist # WORKAROUND: MAKE EXIST TO PREVENT ERROR
 #for THISDUMP in $SRCDUMP `cat ${TMPID}.splitlist | sort -u`
 # do

      THISDUMP=$SRCDUMP
      HTML=`echo $THISDUMP | sed 's/\.[a-z]*$/.html/'`

   # WORKAROUND: FIRST LINE = TMP1 TO PRESERVE LEADING COMMENTS; RM LATER
     echo "TMP1"   >  tmp.tmp
     cat $THISDUMP >> tmp.tmp
     mv tmp.tmp $THISDUMP

   # ------------------------------------------------------------------------- #
   # MAKE CITATIONS
   # ------------------------------------------------------------------------- #

  for CITATION in `sed "s/$CITEOPEN/\n&/g" $THISDUMP | #
                   sed "s/$CITECLOSE/&\n/g" | #
                   grep "^$CITEOPEN"`
   do
      CITEKEY=`echo $CITATION        | #
               sed "s/$CITECLOSE//g" | #
               sed "s/$CITEOPEN//g"  | #
               sed "s/^.*$CITEPCLOSE//"`
      OPTIONAL=`echo $CITATION | #
                grep ${CITEPCLOSE} | #
                sed "s/$CITEOPEN//g"  | #
                sed "s/${CITEPCLOSE}.*$//"`
       LINENUM=`grep -n $CITATION $THISDUMP | #
                head -n 1 | #
                cut -d ":" -f 1`

    if [ "X$CITEKEY" != "X$LASTKEY" ]; then

      COLLECTNAMES="";TITLE=""
      BIBENTRY=`grep $CITEKEY $BIBTMP`

      XID="<genre"
      GENRE=`echo $BIBENTRY   | sed "s/$XID/\n&/g" | #
             grep "^$XID"     | head -n 1          | #
             cut -d ">" -f 2  | cut -d "<" -f 1`     #
      XID="<title>"
      TITLE=`echo $BIBENTRY   | sed "s/$XID/\n&/g" | #
             grep "^$XID"     | head -n 1          | #
             cut -d ">" -f 2  | cut -d "<" -f 1`     #
      XID="<subTitle>"
      STITLE=`echo $BIBENTRY   | sed "s/$XID/\n&/g" | #
              grep "^$XID"     | head -n 1          | #
              cut -d ">" -f 2  | cut -d "<" -f 1`     #
      if [ `echo $STITLE | wc -c` -gt 2 ]; then
           TITLE="${TITLE}: ${STITLE}"
      else
           TITLE="$TITLE"
      fi
      if [  `echo $TITLE | wc -c` -gt 2 ]; then
              TITLE="<span class=\"title\">$TITLE</span>, "
         else
              TITLE=""
      fi
      XID="<dateIssued>"
      DATE=`echo $BIBENTRY   | sed "s/$XID/\n&/g" | #
            grep "^$XID"     | head -n 1          | #
            cut -d ">" -f 2  | cut -d "<" -f 1`     #
      if [  `echo $DATE | wc -c` -gt 2 ]; then
              DATE="<span class=\"date\">${DATE}</span>"
         else
              DATE=""
      fi
      XID="<publisher>"
      PUBLISHER=`echo $BIBENTRY   | sed "s/$XID/\n&/g" | #
                 grep "^$XID"     | head -n 1          | #
                 cut -d ">" -f 2  | cut -d "<" -f 1`     #
      if [  `echo $PUBLISHER | wc -c` -gt 2 ]; then
              PUBLISHER="<span class=\"publisher\">${PUBLISHER}</span>, "
         else
              PUBLISHER=""
      fi
      XID="<placeTerm type=\"text\""
      PLACE=`echo $BIBENTRY   | sed "s/$XID/\n&/g" | #
             grep "^$XID"     | head -n 1          | #
             cut -d ">" -f 2  | cut -d "<" -f 1`     #
      if [  `echo $PLACE | wc -c` -gt 2 ]; then
              PLACE="<span class=\"place\">${PLACE}</span>, "
         else
              PLACE=""
      fi

      K=$RANDOM ; L=`echo $K | rev`
      XID="<name type=\"personal\""
      for PERSONS in `echo $BIBENTRY     | #
                      sed "s/$XID/\n&/g" | #
                      grep "^$XID" | #
                      sed 's/ /5pA4c3e/g'`

      do
          PERSONS=`echo $PERSONS | sed 's/5pA4c3e/ /g'`
          XID="<namePart type=\"given\""
          GNAME=`echo $PERSONS   | sed "s/$XID/\n&/g" | #
                 grep "^$XID"     | head -n 4         | #
                 cut -d ">" -f 2  | cut -d "<" -f 1`    #
          XID="<namePart type=\"family\""
          FNAME=`echo $PERSONS   | sed "s/$XID/\n&/g" | #
                 grep "^$XID"     | head -n 4         | #
                 cut -d ">" -f 2  | cut -d "<" -f 1`    #
          COLLECTNAMES="${COLLECTNAMES}${K} <span class=\"fname\">${FNAME}</span>,\
                        <span class=\"gname\">${GNAME}</span>"
      done

      COLLECTNAMES=`echo $COLLECTNAMES | #
                    sed "s/^$K //"     | #
                    rev | sed "s/$L/ dna /" | #
                    rev | sed "s/$K/,/g"`

      CITEINSERT=`echo "$FOOTNOTEOPEN<span class=\"$GENRE\">\
            ${COLLECTNAMES}: ${TITLE}${PUBLISHER}${PLACE}${DATE}. \
            $OPTIONAL \
            </span>$FOOTNOTECLOSE" | #
      sed 's/>[ ]*</></g'         | #
      tr -s ' '                  | #
      sed 's/"/\\\\"/g'         | #
      sed 's/&/\\\\&/g'        | #
      sed 's/\\//\\\\\//g'    | #
      sed 's/]/\\\\]/g'      | #
      sed 's/\[/\\\\\[/g'`    #

      sed -i "${LINENUM}s/$CITATION/$CITEINSERT/" $THISDUMP

    else
         CITEINSERT="$FOOTNOTEOPEN<span class=\"ibid\">ibid. $OPTIONAL<\/span>$FOOTNOTECLOSE"
         sed -i "${LINENUM}s/$CITATION/$CITEINSERT/" $THISDUMP
    fi

      LASTKEY="$CITEKEY"
  done

   # ------------------------------------------------------------------------- #
   # MAKE FOOTNOTES
   # ------------------------------------------------------------------------- #

 ( IFS=$'\n' ; COUNT=1

  for FOOTNOTE in `sed "s/$FOOTNOTEOPEN/\n&/g" $THISDUMP | #
                   sed "s/$FOOTNOTECLOSE/&\n/"          | # 
                   grep "^$FOOTNOTEOPEN"`
   do
      if [ $COUNT -eq 1 ]; then
           echo "<div class=\"footnotes\">"  >> $THISDUMP
           echo "<ol>"                       >> $THISDUMP
           FOOTNOTEBLOCKSTARTED="YES"
      fi
      LNUM=`grep -n $FOOTNOTE $THISDUMP | head -n 1 | cut -d ":" -f 1`

      FOOTNOTETXT=`echo $FOOTNOTE    | #
                   cut -d "{" -f 2   | #
                   cut -d "}" -f 1`    #
      ID=`echo $FOOTNOTETXT | md5sum | #
          cut -c 1-8`                  #
      FOOTNOTE=`echo $FOOTNOTE       | #
                sed 's/\[/\\\[/g'    | #
                sed 's/|/\\|/g'`
      OLDFOOTNOTE=$FOOTNOTE
      NEWFOOTNOTE="<sup><a href=\"#$ID\">$COUNT</a><\/sup>"
      sed -i "$((LNUM))s|$OLDFOOTNOTE|$NEWFOOTNOTE|" $THISDUMP
      echo "<li id=\"$ID\"> $FOOTNOTETXT </li>"   >> $THISDUMP
      COUNT=`expr $COUNT + 1`
  done

  if [ "X${FOOTNOTEBLOCKSTARTED}" == "XYES" ]; then
        echo "</ol>"           >> $THISDUMP
        echo "</div>"          >> $THISDUMP
        sed -i "s|$FOOTNOTECLOSE||g" $THISDUMP # WORKAROUND (BUG!!)
  fi

  )

# --------------------------------------------------------------------------- #



     #tac $HTML | #
     #sed -n "/<!--.*${HEADMARK}.*-->$/,\$p" | #
     #tac > ${HTML}.tmp
     #echo "" >> ${HTML}.tmp

     echo '<!DOCTYPE html>' > ${HTML}.tmp
     echo '<head><title>Behind the Smart World</title><meta charset="utf-8"/>' >> ${HTML}.tmp
     echo '<link rel="stylesheet" type="text/css" media="all" href="epub.css">' >> ${HTML}.tmp
     echo '</head><body>' >> ${HTML}.tmp

      cat $THISDUMP               | #
      sed "s/[ \t]*$APND//g"      | # DOUBLED FROM FUNCTIONS (BUG?!)
      sed "s/[ \t]*$ESC//g"       | # DOUBLED FROM FUNCTIONS (BUG?!)
      tidy -config tc.txt         | #
      sed 's/^TMP1[ ]*//'         | # RM ADDED DUMMY
      grep -v '^<!--'             | #
      sed -e :a \
          -e '$!N;s/=[ ]*\n"/="/;ta' \
          -e 'P;D'                | # REAPPEND UNTIDY TIDY BREAK (=")
      tee >> ${HTML}.tmp

      echo '</body></html>' >> ${HTML}.tmp
    
     #sed -n "/<!--.*${FOOTMARK}.*-->$/,\$p" ${HTML} >> ${HTML}.tmp
    
      mv ${HTML}.tmp $HTML
     # BUG: INCLUDES INTERPUNCTUATION
     # sed -i '/^<!-- /!s,\([>]*\)\(http.\?://[^ <]*\),\1<a href="\2" class="linkify">\2</a>,g' $HTML
      rm $THISDUMP

 #done

  pandoc --epub-stylesheet lib/epub/css/epub.css \
         --epub-embed-font=lib/epub/fonts/inconsolata_regular.ttf \
         --epub-embed-font=lib/epub/fonts/hkgrotesk_regular.ttf  \
         -i $HTML -o __/BTSW_160223.epub
  rm $HTML

 #mv `echo $SRCDUMP | sed 's/\.[a-z]*$/.html/'` $MAINHTML

# =========================================================================== #
# CLEAN UP

# SHOULD HAVE rmif FUNCTION
  rm tc.txt
  rm ${TMPID}*.[1-9]*.*
  rm ${TMPID}*.functions
  rm ${TMPID}*.included
  rm ${TMPID}*.tmp
  rm ${TMPID}*.txt
  rm ${TMPID}*.pdf
  rm ${TMPID}*.png
  rm ${TMPID}*.wget
  rm ${TMPID}*.*list
  #rm ${TMPID}bib*
  rm ${TMPID}.bibtmp 
  rm ${TMPID}*.fid
  
  
exit 0;

