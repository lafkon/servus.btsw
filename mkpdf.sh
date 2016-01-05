#!/bin/bash

# THIS IS A FRAGILE SYSTEM, HANDLE WITH CARE.                                #
# --------------------------------------------------------------------------- #

  MAIN=Behind_The_Smart_World_PDF.mdsh
 #MAIN=DEBUG.mdsh

  TMPDIR=. ;  TMPID=$TMPDIR/TMP`date +%Y%m%H``echo $RANDOM | cut -c 1-4`
  SRCDUMP=${TMPID}.maindump
  OUTDIR=FREEZE
  SELECTLINES="tee"
  TMPTEX=${TMPID}.tex

# =========================================================================== #
# CONFIGURATION                                                               #
# --------------------------------------------------------------------------- #
  source lib/sh/prepress.functions

# INCLUDE/COMBINE FUNCTIONS
# --------------------------------------------------------------------------- #
  FUNCTIONSBASIC=lib/sh/201512_basic.functions
   FUNCTIONSPLUS=lib/sh/151208_pdf.functions
       FUNCTIONS=$TMPID.functions
  cat $FUNCTIONSBASIC $FUNCTIONSPLUS > $FUNCTIONS
  source $FUNCTIONS

# --------------------------------------------------------------------------- #
# GET BIBREF FILE
# --------------------------------------------------------------------------- #
  REFURL="http://freeze.sh/etherpad/export/_/references.bib"
  # wget --no-check-certificate \
  #      -O ${TMPID}.bib $REFURL > /dev/null 2>&1
  getFile $REFURL ${TMPID}.bib

# --------------------------------------------------------------------------- #
# DEFINITIONS SPECIFIC TO OUTPUT
# --------------------------------------------------------------------------- #
 #PANDOCACTION="pandoc --ascii -V links-as-notes -r markdown -w latex"
  PANDOCACTION="pandoc --ascii -r markdown -w latex"
# --------------------------------------------------------------------------- #
# FOOTNOTES
# \footnote{the end is near, the text is here}
# --------------------------------------------------------------------------- #
  FOOTNOTEOPEN="\footnote{" ; FOOTNOTECLOSE="}"
# CITATIONS
# \cite{phillips:2004:vectoraesthetic}
# --------------------------------------------------------------------------- #
  CITEOPEN="\cite{"   ; CITECLOSE="}"
# --------------------------------------------------------------------------- #
  CITEPOPEN="\citep[" ; CITEPCLOSE="]{"
# =========================================================================== #

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# --------------------------------------------------------------------------- #
# ACTION STARTS HERE!
# --------------------------------------------------------------------------- #
  mdsh2src $MAIN


  if [ `ls $SRCDUMP 2>/dev/null | wc -l` -gt 0 ]; then
# --------------------------------------------------------------------------- #
# WRITE TEX SOURCE
# --------------------------------------------------------------------------- #
  TMPTEXSANSEXT=`echo $TMPTEX | rev | cut -d "." -f 2- | rev`

  echo "\documentclass[10pt,cleardoubleempty]{scrbook}" >  $TMPTEX
  echo "\usepackage{lib/tex/151208_A5}"                 >> $TMPTEX
  echo "\bibliography{${TMPID}.bib}"                    >> $TMPTEX
# PDF/X COMPLIANCY
  echo "\usepackage[x-1a]{pdfx}"                        >> $TMPTEX
  echo "<?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d'?>" > pdfx-1a.xmp
  cp lib/icc/FOGRA39L.icc .
  echo "\Keywords{pdfTeX\sep PDF/X-1a\sep PDF/A-b}
  \Title{Behind the Smart World}
  \Author{LAFKON Publishing}
  \Org{servus.at, Linz}
  \Doi{123456789}" > ${TMPTEXSANSEXT}.xmpdata
  echo '\pdfpageattr{/MediaBox [0 0 436 612]
               /TrimBox [8 8 428 604]}
        \pdfcatalog{
        /OutputIntents [ <<
       /Info (none)
      /Type /OutputIntent
     /S /GTS_PDFX
    /OutputConditionIdentifier (OFCOM_PO_P1_F60_95)
   /RegistryName (http://www.color.org/)
   >> ]
       }'                                               >> $TMPTEX
  echo "\begin{document}"                               >> $TMPTEX
# --------------------------------------------------------------------------- #
# LAST MINUTE CORRECTIONS (NOT SO NICE)
# --------------------------------------------------------------------------- #
  sed -i -e 's/\(\([0-9]\)\+\)\(st\|nd\|rd\|th\)\+\b/\1\\ts{\3}/g' $SRCDUMP
  sed -i "s/--\\\textgreater{}/\\\ding{222}/g"                     $SRCDUMP

 # STILL DEBUGGING <- CLEAN THIS UP
 #sed -i 's/\bhttp.\?:[^ ]* /\\urlsplit{&}/g'                      $SRCDUMP
 #sed -i 's/\bhttp.\?:[^ ]* [,.)}]*/\\urlsplit{&}/g'               $SRCDUMP
 #sed -i '/\\urlsplit/s/\\index{[^}]*}//g'                         $SRCDUMP
 #sed -i '/\\urlsplit/s/\\index{[a-zA-Z. ]*}//g'                   $SRCDUMP
  sed -i '/http.\?:\/\//s/\\index{[a-zA-Z. ]*}//g' $SRCDUMP
 #sed -i 's/\bhttp.\?:.*\b/\\urlsplit{&}/g'               $SRCDUMP
  sed -i 's/\(\bhttp.\?:[^ ]*\) /\\urlsplit{\1} /g' $SRCDUMP

  cat   $SRCDUMP                                        >> $TMPTEX
  echo "\end{document}"                                 >> $TMPTEX
 
# --------------------------------------------------------------------------- #
# MAKE PDF
# --------------------------------------------------------------------------- #

  pdflatex -interaction=nonstopmode \
            $TMPTEX  # > /dev/null
  biber `echo ${TMPTEX} | rev | cut -d "." -f 2- | rev`
  makeindex -s ${TMPID}.ist ${TMPTEXSANSEXT}.idx
  pdflatex -interaction=nonstopmode \
            $TMPTEX  # > /dev/null
  pdflatex -interaction=nonstopmode \
            $TMPTEX  # > /dev/null

# D E B U G D E B U G D E B U G D E B U G D E B G D E B U D E B U G D E B U G #
  cp ${TMPID}.pdf debug.pdf
  cp $TMPTEX debug.tex

  else 

  echo "not existing"

  fi

# =========================================================================== #
# CLEAN UP

# SHOULD HAVE rmif FUNCTION
  rm $SRCDUMP
  rm ${TMPID}*.[1-9]*.*
  rm ${TMPID}*.functions
  rm ${TMPID}*.included
  rm ${TMPID}.tex
  rm ${TMPID}.aux
 #rm ${TMPID}.pdf
  rm ${TMPID}.log
  rm ${TMPID}*.pdf
  rm ${TMPID}*.bib
  rm ${TMPID}*.wget
  rm ${TMPID}*.info
  rm ${TMPID}*.toc
  rm ${TMPID}*.licenses
  rm ${TMPID}*.qrurls
  rm ${TMPID}SRC*.*
# BIBER
  rm ${TMPID}*.bbl
  rm ${TMPID}*.bcf
  rm ${TMPID}*.blg
 #rm ${TMPID}*.out
  rm ${TMPID}*.run.xml
# INDEX  
  rm ${TMPID}.keywords
  rm ${TMPID}.idx
  rm ${TMPID}.ist
  rm ${TMPID}.ilg
  rm ${TMPID}.ind

  rm ${TMPID}.xmpdata
  rm FOGRA39L.icc
  rm pdfx-1a.xmp*

  if [ `ls ${TMPID}.fid 2>/dev/null | wc -l` -gt 0 ];then
  rm ${TMPID}.fid
  fi

exit 0;


