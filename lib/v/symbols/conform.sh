#!/bin/bash
 
        PDF=$1
        if [ `ls -a $1      | # SUPRESS IF  $1 IS EMPTY
              head -n 1     | # SUPRESS IF  $1 IS EMPTY
              grep "\.pdf$" | # CHECK IF ENDS WITH .pdf
              wc -l` -gt 0  ]; then
          cp $1 tmp.pdf
          gs                                     \
            -o $1                                \
            -sDEVICE=pdfwrite                    \
            -sColorConversionStrategy=Gray       \
            -sProcessColorModel=DeviceGray       \
            -sColorImageDownsampleThreshold=2    \
            -sColorImageDownsampleType=Bicubic   \
            -sColorImageResolution=300           \
            -sGrayImageDownsampleThreshold=2     \
            -sGrayImageDownsampleType=Bicubic    \
            -sGrayImageResolution=300            \
            -sMonoImageDownsampleThreshold=2     \
            -sMonoImageDownsampleType=Bicubic    \
            -sMonoImageResolution=1200           \
            -dSubsetFonts=true                   \
            -dEmbedAllFonts=true                 \
            -dAutoRotatePages=/None              \
            -sCannotEmbedFontPolicy=Error        \
            -c ".setpdfwrite<</NeverEmbed[ ]>> setdistillerparams" \
            -f tmp.pdf > /dev/null
          rm tmp.pdf
        else
         echo "nothing to do!"
        fi

exit 0;
