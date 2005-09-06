#!/bin/bash

VERSION=0.1

#set -e

cd ../xmpp4r/
rake package
cd ../pkg-debian
cp ../xmpp4r/pkg/xmpp4r-$VERSION.tgz xmpp4r_$VERSION.orig.tar.gz
tar xzf xmpp4r_$VERSION.orig.tar.gz
#mv xmpp4r-$VERSION libxmpp4r-ruby-$VERSION
cd xmpp4r-$VERSION
cp -r ../debian .
rm -rf debian/.svn
dpkg-buildpackage -rfakeroot
cd ..
dpkg-scanpackages . /dev/null >Packages
dpkg-scansources . /dev/null >Sources
gzip Packages
gzip Sources
rm -rf xmpp4r-$VERSION
