#!/bin/bash

  ODTDIR=odt
 MDSHDIR=mdsh

  TMPDIR=.
   TMPID=XX
     TMP=$TMPDIR/$TMPID

 # TMP PLACEHOLDER
 # ----------------------------------- #
 L="L${RANDOM}I" # PROTECT EMPTY LINES
 B="B${RANDOM}R" # PROTECT LINE BREAKS
 S="S${RANDOM}P" # PROTECT WHITE SPACE
 C=CO${RANDOM}DE # PROTECT CODE BLOCKS
 M=M${RANDOM}    # MARK SOMETHING


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

  for ODT in `ls $ODTDIR/*.odt`
   do
      MDSH=$MDSHDIR/`basename $ODT | #
                     cut -d "." -f 1`.mdsh
      if [ $ODT -nt $MDSH ]; then 
      if [ -f $MDSH ] &&
         [ `git ls-files $MDSH | wc -l` -lt 1 ] ||
         [ `git ls-files -m $MDSHDIR | #
            grep $MDSH | wc -l` -gt 0 ]; then
            echo "$MDSH not commited"
            echo "=> doing nothing"
      else
          echo "writing $MDSH"

# BASIC CONVERSION
# -------------------------------------------------------------------------- #

  cp $ODT ${TMP}.odt
  soffice --headless --convert-to html:HTML --outdir $TMPDIR ${TMP}.odt
 
  pandoc --no-wrap \
         -r html -w markdown ${TMP}.html | # FROM HTML TO MARKDOWN WITHOUT WRAP
  sed '/^\\$/d'                          | # DELETE LINES WITH BACKSLASH ONLY
  sed "/^%/s/ /$S/g"                     | # PROTECT SPACES FOR COMMENTS
  pandoc -r markdown -w markdown         | # PANDOC JUST TO WRAP
  sed "s/^[ \t]*$/$L/"                   | # REMOVE EMPTY LINES (TEMPORARY)
  sed ":a;N;\$!ba;s/\n/$B/g"             | # REMOVE LINEBREAKS (TEMPORARY)
  sed "s/$L/\n/g"                        | # RESTORE EMPTY LINES
  sed "s/${B}$//g"                       | # REMOVE LINEBREAKS AT LINEBREAKS
  sed "/^${B}\*.*\*$/s/$B/&> /g"         | # 'ALL ITALIC' PARAGRAPHS BECOME QUOTES
  sed "s/$B/\n/g"                        | # RESTORE LINEBREAKS 
  sed "s/^> \*/> /" | sed "/^>/s/\*$//"  | # REMOVE MARKDOWN ITALIC FROM QUOTE LINES
  sed "s/\\\\$/\n/"                      | # MAKE LINE BREAKS PARAGRAPHS
  tee > ${TMP}.mdsh

# FOOTNOTES
# -------------------------------------------------------------------------- #

  for FOOTNOTE in `cat ${TMP}.mdsh                | # PIPE STARTS
                   sed "s/\[\^[0-9]*\^\]/\n$M&/g" | # FOOTNOTES ON NEWLINE AND MARK
                   sed "s/)/&\n/"                 | # NEWLINE AFTER FOOTNOTE
                   grep "^$M\[" | cut -d " " -f 1 | # SELECT FOOTNOTE
                   sed "s/$M//"`                    # REMOVE MARK
   do 
      FOOTNOTEANC=`echo $FOOTNOTE  |  # START
                   cut -d "(" -f 2 |  # CUT SECOND FIELD
                   cut -d ")" -f 1 |  # CUT FIRST FIELD
                   sed 's/sym$/anc/'` # PUT ID
      FOOTNOTECONTENT=`sed ':a;N;$!ba;s/\n/ /g' ${TMP}.mdsh | # RM NEWLINES
                       sed "s/\[[0-9]*\]/\n&/g"             | # NEWLINE BEFORE
                       grep "^\[[0-9]*\]($FOOTNOTEANC"      | # SELECT THIS ANCHOR
                       cut -d ")" -f 2-                     | # CUT FIELD
                       sed 's/[ \t]*$//'`                     # RM BLANKS AT END
      FTNTANC4SED=`echo $FOOTNOTEANC  | # ESCAPE FOR SED
                   sed 's/\^/\\\\^/g' | # ESCAPE FOR SED
                   sed 's/\[/\\\\[/g'`  # ESCAPE FOR SED
      FTNT4SED=`echo $FOOTNOTE     | # ESCAPE FOR SED 
                sed 's/\\\/\\\\\\\/g' | # ESCAPE FOR SED
                sed 's/\^/\\\\^/g' | # ESCAPE FOR SED
                sed 's/\[/\\\\[/g'`  # ESCAPE FOR SED
      FTNTCNTNT4SED=`echo $FOOTNOTECONTENT | # ESCAPE FOR SED
                     sed 's/\&/\\\\&/g'`     # ESCAPE FOR SED
      MDSHFOOTNOTE="[^]{$FTNTCNTNT4SED}"
 
      sed -i "s|$FTNT4SED|$MDSHFOOTNOTE|"    ${TMP}.mdsh
      sed -i ":a;N;\$!ba;s/\n/$B/g"          ${TMP}.mdsh
      sed -i "s/$B\[[0-9]*\]/\n&/g"          ${TMP}.mdsh
      sed -i "/^$B\[[0-9]*\]($FTNTANC4SED/d" ${TMP}.mdsh
      sed -i "s/$B/\n/g"                     ${TMP}.mdsh
 
  done

# OBSESSIVE-COMPULSIVE CLEAN UP (MAKE IT NICE!)
# -------------------------------------------------------------------------- #

  cat -s ${TMP}.mdsh         | # CAT WITHOUT DUPLICATE EMPTY LINES
  sed "s/^[ \t]*$/$L/"       | # PROTECT EMPTY LINES
  sed "s/^    /$B$C/"        | # PROTECT MARKDOWN CODE BLOCKS
  sed "/^>/s/^/$B/"          | # PROTECT MARKDOWN QUOTE BLOCKS
  sed "s/^[-=]\{5,\}$/$B&/"  | # PROTECT MARKDOWN UNDERLINE (CHAPTER/SECTION)
  sed "s/[ ]\{3,\}$/&$B/"    | # PROTECT MARKDOWN LINE BREAKS
  sed ':a;N;$!ba;s/\n/ /g'   | # REMOVE  LINE BREAKS
  sed "s/$L/\n\n/g"          | # RESTORE EMPTY LINES
  sed "/$B/s/ /$S/g"         | # RM WHITE SPACE FOR PROTECTED MARKDOWN
  sed "s/$B/\n/g"            | # RESTORE LINE BREAKS FOR PROTECTED MARKDOWN
  fmt -s -w 78               | # NOT EIGHTY COLUMNS
  sed "s/$S/ /g"             | # RESTORE WHITE SPACE
  sed "s/^[ \t]*//"          | # RM LEADING BLANKS
  tr -s ' '                  | # SQUEEZE BLANKS
  sed "s/$C/    /"           | # RESTORE CODE BLOCKS
  sed '/./,/^$/!d'           | # COMBINE CONSECUTIVE BLANK LINES
  sed '/^%[ A-Z]*:/s/\\//g'  | # DE-ESCAPE WITHIN COMMAND LINES
  tee > $MDSH                  # WRITE TO FILE

# RM TMP FILES
# -------------------------------------------------------------------------- #
  rm ${TMP}.odt ${TMP}.html ${TMP}.mdsh

     fi; else echo "$MDSH is up-to-date"
     fi
  done
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


exit 0;

