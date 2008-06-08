#!/bin/bash

# Generate a full graph of the requires in the Ruby files of this library.
#
# Output : The graph is generated as a .png file in the same dir as this script.
#
# This script requires the following tools to be installed:
#
# * mktemp
# * dot (Try 'sudo port install graphviz' on OS X)

export TMPDIR='/tmp'
export TMPFILE=$(mktemp $TMPDIR/gen_requires.XXXXXX)
export OUTFILE='gen_requires.png'
export SELFDIR=`pwd`
export LIBDIR=$SELFDIR/../lib

#######################################
# Unlikely you need to edit below here
#######################################

cd $LIBDIR

echo "strict digraph requirestree { " > $TMPFILE
grep -r "^require " * | grep -v swp | sed "s/^\(.*\).rb:require '\(.*\)'/\1 -> \2;/" | sed 's/\//_/g' >> $TMPFILE
echo "}" >> $TMPFILE

cd $SELFDIR
dot -Tpng $TMPFILE -o $OUTFILE
rm -f $TMPFILE

