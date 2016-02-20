#!/bin/bash

# =========================================================================== #
# THIS IS A FRAGILE SYSTEM, HANDLE WITH CARE.                                #
# =========================================================================== #

 #MAIN=$1
  MAIN="Behind_The_Smart_World_HTML.mdsh"
 #HTML=$2
  HTML="__/html/all.html"

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
  if [ -f $HTML ]; then
       echo "$HTML does exist"
       read -p "overwrite $HTML? [y/n] " ANSWER
       if [ X$ANSWER != Xy ] ; then echo "BYE BYE!"; exit 1; fi
  else
       touch $HTML
  fi

   HTMLBASE=`realpath $HTML | rev | cut -d "/" -f 2- | rev`
   HTMLSRCDIRNAME="_"
   HTMLSRCDIR="$HTMLBASE/$HTMLSRCDIRNAME"
  if [ ! -d $HTMLSRCDIR ]; then
       echo
       echo "$HTMLSRCDIR does not exist"
       read -p "create $HTMLSRCDIR? [y/n] " ANSWER
       if [ X$ANSWER == Xy ] ; then 
       echo "creating $HTMLSRCDIR"; mkdir $HTMLSRCDIR
       else echo "BYE BYE!"; exit 1; fi
  fi
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
   FUNCTIONSPLUS=lib/sh/160220_html.functions
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
  CITEPOPEN="$CITEOPEN" ; CITEPCLOSE="$CITECLOSE"
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
# PROCESS HTML
# --------------------------------------------------------------------------- #
# http://tidy.sourceforge.net/docs/quickref.html#show-body-only 
  echo "show-body-only: y"     >  tc.txt
  echo "wrap-attributes: n"    >> tc.txt
  echo "quiet:y"               >> tc.txt
  echo "vertical-space:y"      >> tc.txt

  MAINHTML="$HTML"
  cp $HTML `echo $SRCDUMP | sed 's/\.[a-z]*$/.html/'`

  for THISDUMP in $SRCDUMP `cat ${TMPID}.splitlist | sort -u`
   do
      HTML=`echo $THISDUMP | sed 's/\.[a-z]*$/.html/'`
      echo $HTML

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

      tac $HTML | #
      sed -n "/<!--.*${HEADMARK}.*-->$/,\$p" | #
      tac > ${HTML}.tmp
      echo "" >> ${HTML}.tmp
      
      cat $THISDUMP               | #
      sed "s/[ \t]*$APND//g"      | # DOUBLED FROM FUNCTIONS (BUG?!)
      sed "s/[ \t]*$ESC//g"       | # DOUBLED FROM FUNCTIONS (BUG?!)
     #grep -v "^${COMSTART}"      | #
      tidy -config tc.txt         | #
      sed -e :a \
          -e '$!N;s/=[ ]*\n"/="/;ta' \
          -e 'P;D'                | # REAPPEND UNTIDY TIDY BREAK (=")
      tee >> ${HTML}.tmp
    
      sed -n "/<!--.*${FOOTMARK}.*-->$/,\$p" ${HTML} >> ${HTML}.tmp
    
      mv ${HTML}.tmp $HTML
      rm $THISDUMP

  done


  mv `echo $SRCDUMP | sed 's/\.[a-z]*$/.html/'` $MAINHTML




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

  
exit 0;

