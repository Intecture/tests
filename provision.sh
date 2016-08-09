#!/usr/bin/env sh
# Copyright 2015-2016 Intecture Developers. See the COPYRIGHT file at the
# top-level directory of this distribution and at
# https://intecture.io/COPYRIGHT.
#
# Licensed under the Mozilla Public License 2.0 <LICENSE or
# https://www.tldrlegal.com/l/mpl-2.0>. This file may not be copied,
# modified, or distributed except according to those terms.

# Install package dependencies
case $1 in
    centos )
        yum update -y
        yum -y install git libtool gcc-c++ glib* curl-devel zlib-devel openssl-devel php-devel
        ;;

    debian )
        apt-get update -y
        apt-get -y install git build-essential pkg-config curl php5-dev
        ;;

    fedora )
        dnf update -y
        dnf -y install git libtool gcc-c++ glib* curl-devel zlib-devel openssl-devel php-devel
        ;;

    freebsd )
        env ASSUME_ALWAYS_YES=YES sudo pkg install git libtool gcc glib gmake automake autoconf pkgconf php
        ;;

    ubuntu )
        apt-get update -y
        apt-get -y install git build-essential pkg-config curl php5-dev
        ;;
esac

export LIBRARY_PATH=/usr/local/lib
export LD_LIBRARY_PATH=/usr/local/lib
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export PATH=$PATH:/usr/local/bin
export RUST_BACKTRACE=1

# Install ZMQ
cd /tmp
curl -sSOL https://download.libsodium.org/libsodium/releases/libsodium-1.0.8.tar.gz
curl -sSOL https://download.libsodium.org/libsodium/releases/libsodium-1.0.8.tar.gz.sig
curl -sSOL https://download.libsodium.org/jedi.gpg.asc
gpg --import jedi.gpg.asc
gpg --verify libsodium-1.0.8.tar.gz.sig libsodium-1.0.8.tar.gz
tar zxf libsodium-1.0.8.tar.gz
cd libsodium-1.0.8
./configure && make && make install || exit 1
cd ..

curl -sSOL https://github.com/zeromq/zeromq4-1/archive/v4.1.4.tar.gz
tar zxf v4.1.4.tar.gz
cd zeromq4-1-4.1.4
./autogen.sh && ./configure --with-libsodium && make && make install || exit 1
cd ..

git clone https://github.com/zeromq/czmq
cd czmq
./autogen.sh && ./configure && make && make install || exit 1

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
. ~/.cargo/env

# Install projects and run tests
/vagrant/run.sh
