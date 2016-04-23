#!/bin/bash
#
#    |                 
# /~~|/~~||/~\ /~\ |~~\
# \__|\__||   |   ||__/
#                  |   
#
# damp 1.0
# 
# Enable SSL2, SSL3 and weak cipher support in OpenSSL
# Useful for detecting Drown (CVE-2016-0800)
#
# - Elly

# Halt script on fail
set -e 

# Install dependencies
apt install build-essential devscripts quilt bc -y

# Capture Current Dir
origin=$(pwd)

# Create & Move into temp file
cd $(mktemp -d)

# Pull openssl source
apt source openssl
cd openssl*

# If SSL2 is disabled in a patch, patch it back in.
if [ $(grep -i ssl2 debian/patches/series)  ]; then

  # Pop patches
  quilt pop -a

  # Edit Series, comment out ssl2 patch
  sed -ri 's/(.*ssl2.*)/#\1/ig' debian/patches/series 

  # Re-apply patches
  quilt push -a

fi


# Edit Rules
# On CONFARGS line, take out "no-ssl2", "no-ssl3" and "no-ssl3-method"
# Then add in "enable-ssl2" and "enable-weak-ssl"
sed -ri 's/(no-ssl2[\ ]*|no-ssl3[\ ]*|no-ssl3-method[\ ]*)//g' debian/rules
sed -ri 's/(^CONFARGS.*)/\1\ enable-ssl2 enable-weak-ssl/g' debian/rules

# Add entry in changelog
dch -n 'Allow SSLv2, SSLv3 and weak ciphers'

# Commit changes
dpkg-source --commit

# Build Deb file
debuild -uc -us

# Install Package
dpkg -i ../*ssl*.deb

# Move back to original directory
cd $origin
