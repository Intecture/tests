#!/usr/bin/env sh
# Copyright 2015-2016 Intecture Developers. See the COPYRIGHT file at the
# top-level directory of this distribution and at
# https://intecture.io/COPYRIGHT.
#
# Licensed under the Mozilla Public License 2.0 <LICENSE or
# https://www.tldrlegal.com/l/mpl-2.0>. This file may not be copied,
# modified, or distributed except according to those terms.

MAKEALIAS="make"

# Install package dependencies
case $1 in
    centos )
        rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
        rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
        yum update -y
        yum -y install git libtool gcc-c++ glib* curl-devel zlib-devel openssl-devel php70w-devel
        ;;

    debian )
        echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
        echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
        wget https://www.dotdeb.org/dotdeb.gpg
        sudo apt-key add dotdeb.gpg
        apt-get update
        apt-get -y install git build-essential pkg-config curl php7.0-dev
        ;;

    fedora )
        wget http://rpms.remirepo.net/fedora/remi-release-24.rpm
        dnf install -y remi-release-24.rpm
        dnf update -y
        dnf -y --enablerepo=remi-php70 install git libtool gcc-c++ glib* curl-devel zlib-devel openssl-devel php-devel
        ;;

    freebsd )
        pkg update -f && pkg check -Ba
        pkg upgrade -y
        pkg install -y git libtool gcc glib gmake automake autoconf pkgconf php70 curl gnupg
        cp /usr/local/etc/php.ini-development /usr/local/etc/php.ini
        MAKEALIAS="gmake"
        ;;

    ubuntu )
        add-apt-repository ppa:ondrej/php
        apt-get update
        apt-get -y install git build-essential libtool pkg-config curl php7.0-dev
        ;;
esac

export LIBRARY_PATH=/usr/local/lib
export LD_LIBRARY_PATH=/usr/local/lib
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export PATH=$PATH:/usr/local/bin
export RUST_BACKTRACE=1

cd /var/tmp

# Install ZMQ
if [ ! -d zeromq-4.2.0 ]; then
    curl -sSOL https://github.com/zeromq/libzmq/releases/download/v4.2.0/zeromq-4.2.0.tar.gz
    tar zxf zeromq-4.2.0.tar.gz
    cd zeromq-4.2.0
    ./autogen.sh && ./configure && $MAKEALIAS && $MAKEALIAS install || exit 1
    cd ..
fi

if [ ! -d czmq-4.0.1 ]; then
    curl -sSOL https://github.com/zeromq/czmq/releases/download/v4.0.1/czmq-4.0.1.tar.gz
    tar zxf czmq-4.0.1.tar.gz
    cd czmq-4.0.1
    ./configure && $MAKEALIAS && $MAKEALIAS install || exit 1
fi

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
. ~/.cargo/env

# Install projects and run tests
/vagrant/run.sh
