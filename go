#!/bin/sh

#of  output file
#ldc2 -w -ofmain main.d -L-L. $@    -g -d-debug=3 -O0 -de 
dmd -w -ofhexism \
  hexism.d \
  -profile=gc   -g -debug    \
 -I=/home/novous/Downloads/DAllegro5/  \
 -I=/home/novous/Downloads/allegro-5/lib/  \
 -I=/home/novous/Downloads/DAllegro5/allegro5/  \
 -I=/usr/local/lib  \
 -I=/home/novous/Desktop/dev6/dgrav   \
 -L-L/home/novous/Downloads/DAllegro5/ \
 -L-L/home/novous/Downloads/allegro-5/lib/ \
 -L-L/home/novous/Downloads/allegro-5/lib/libdallegro5.a

#d-debug=3 -O0 -de  \		<-- not in DMD
#  -profile  

# -g  <--- This works fine (and BETTER) with newer/ish GDB I think! backtrace looks better
# -gc

#-release
# -gc optmize for non-D debuggers
# -O3 max debug (may allow others later)

#  -march=<string>                   - Architecture to generate code for:
#  -mattr=<a1,+a2,-a3,...>           - Target specific attributes (-mattr=help for details)
#  -mcpu=<cpu-name>                  - Target a specific cpu type (-mcpu=help for details)


# TRY THESE
#
# ldc2 -mattr=help
# ldc2 -mcpu=help 


# Talk on supported versions:
# http://llvm.org/devmtg/2014-04/PDFs/LightningTalks/2014-3-31_ClangTargetSupport_LighteningTalk.pdf


# -de  show use of deprecated features as errors (halt compilation) 
#https://wiki.dlang.org/Using_LDC
