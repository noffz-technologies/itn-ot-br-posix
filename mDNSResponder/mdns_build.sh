#!/bin/bash

TAR_PATH=/shared/mdns-install.tar
TMP_DIR=/tmp/mdns-install

cd mDNSPosix
make os=linux tls=no 
mkdir ${TMP_DIR}
cp /etc/nsswitch.conf ${TMP_DIR}/etc/nsswitch.conf

# Replace Makefile with modified one
DESTDIR="${TMP_DIR}" make install os=linux tls=no

# Fix faulty symlink
rm "${TMP_DIR}"/usr/lib/libdns_sd.so
ln -s libdns_sd.so.1 "${TMP_DIR}"/usr/lib/libdns_sd.so

# Create tar
tar cf "${TAR_PATH}" -C "${TMP_DIR}" .