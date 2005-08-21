#!/bin/bash

if [ -z $CVSDIR ]; then
	CVSDIR=$HOME/dev/xmpp4r-web
fi

TARGET=$CVSDIR/rdoc

echo "Copying rdoc documentation to $TARGET."

if [ ! -d $TARGET ]; then
	echo "$TARGET doesn't exist, exiting."
	exit 1
fi
rsync -a rdoc/ $TARGET/

echo "CVS status :"
cd $TARGET
cvs -q up
echo "Commit changes now with"
echo "# (cd $TARGET && cvs commit -m \"rdoc update\")"
exit 0
