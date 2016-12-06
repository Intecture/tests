#!/bin/sh
# Copyright 2015-2016 Intecture Developers. See the COPYRIGHT file at the
# top-level directory of this distribution and at
# https://intecture.io/COPYRIGHT.
#
# Licensed under the Mozilla Public License 2.0 <LICENSE or
# https://www.tldrlegal.com/l/mpl-2.0>. This file may not be copied,
# modified, or distributed except according to those terms.

export RUST_BACKTRACE=1

# Undefined vars are errors
set -u

# Globals
os=
prefix=
libdir=
sysconfdir=
make="make"
php5_version=5.6.28
php7_version=7.0.13

# Install package dependencies
case $1 in
    centos6 )
        os="redhat"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib64"

        yum update -y
        yum -y install git libtool gcc-c++ glib* curl-devel zlib-devel libxml2-devel openssl-devel wget cmake

        # Upgrade version of autoconf
        wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
        tar xvfvz autoconf-2.69.tar.gz
        cd autoconf-2.69
        ./configure
        make && make install
        ;;

    centos7 )
        os="redhat"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib64"

        yum update -y
        yum -y install git libtool gcc-c++ glib* curl-devel zlib-devel libxml2-devel openssl-devel wget cmake

        # Upgrade version of autoconf
        wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
        tar xvfvz autoconf-2.69.tar.gz
        cd autoconf-2.69
        ./configure
        make && make install
        ;;

    debian )
        os="debian"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib"

        apt-get update
        apt-get -y install git build-essential pkg-config curl wget xml2-dev cmake
        ;;

    fedora )
        os="redhat"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib64"

        dnf update -y
        dnf -y --enablerepo=remi-php70 install git libtool gcc-c++ glib* curl-devel zlib-devel libxml2-devel openssl-devel wget cmake
        ;;

    freebsd )
        os="freebsd"
        prefix="/usr/local"
        libdir="$prefix/lib"
        sysconfdir="$prefix/etc"

        pkg update -f && pkg check -Ba
        pkg upgrade -y
        pkg install -y git libtool gcc glib gmake automake autoconf pkgconf curl gnupg wget xml2 cmake
        cp /usr/local/etc/php.ini-development /usr/local/etc/php.ini

        make="gmake"
        ;;

    ubuntu )
        os="debian"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib"

        apt-get update
        apt-get -y install git build-essential libtool pkg-config curl wget xml2-dev cmake
        ;;
esac

cd /var/tmp

# Install ZMQ
if [ ! -d zeromq-4.2.0 ]; then
    curl -sSOL https://github.com/zeromq/libzmq/releases/download/v4.2.0/zeromq-4.2.0.tar.gz
    tar zxf zeromq-4.2.0.tar.gz
    cd zeromq-4.2.0
    ./autogen.sh
    ./configure --prefix=$prefix --libdir=$libdir --sysconfdir=$sysconfdir
    $make && $make install || exit 1
    cd ..
fi

if [ ! -d czmq-4.0.1 ]; then
    curl -sSOL https://github.com/zeromq/czmq/releases/download/v4.0.1/czmq-4.0.1.tar.gz
    tar zxf czmq-4.0.1.tar.gz
    cd czmq-4.0.1
    ./configure --prefix=$prefix --libdir=$libdir --sysconfdir=$sysconfdir
    $make && $make install || exit 1
fi

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
. ~/.cargo/env

# Install PHP
curl -L http://git.io/phpenv-installer | bash
cat << "EOF" >> ~/.bashrc
export PHPENV_ROOT="/root/.phpenv"
export PATH="${PHPENV_ROOT}/bin:${PATH}"
eval "$(phpenv init -)"
EOF
. ~/.bashrc
sed -i -e 's/rbenv/phpenv/g' "$PHPENV_ROOT"/completions/rbenv.{bash,zsh}
sed -i -s 's/\.rbenv-version/.phpenv-version/g' "$PHPENV_ROOT"/libexec/rbenv-local
sed -i -s 's/\.rbenv-version/.phpenv-version/g' "$PHPENV_ROOT"/libexec/rbenv-version-file
sed -i -s 's/\.ruby-version/.php-version/g' "$PHPENV_ROOT"/libexec/rbenv-local
sed -i -s 's/\.ruby-version/.php-version/g' "$PHPENV_ROOT"/libexec/rbenv-version-file
sed -i -e 's/\(^\|[^/]\)rbenv/\1phpenv/g' "$PHPENV_ROOT"/libexec/rbenv-init
sed -i -e 's/\phpenv-commands/rbenv-commands/g' "$PHPENV_ROOT"/libexec/rbenv-init
sed -i -e 's/\Ruby/PHP/g' "$PHPENV_ROOT"/libexec/rbenv-which
phpenv update
cat << "EOF" > ~/.phpenv/plugins/php-build/share/php-build/default_configure_options
--enable-debug
--without-pear
--disable-xml
EOF
phpenv install $php5_version
phpenv install $php7_version
phpenv version-file-write ~/.phpenv/version $php7_version
ln -s ~/.phpenv/versions/$php5_version ~/.phpenv/versions/5.6
ln -s ~/.phpenv/versions/$php7_version ~/.phpenv/versions/7.0

# Install projects and run tests
sed "s~{{os}}~$os~" < /vagrant/run.tpl.sh |
sed "s~{{prefix}}~$prefix~" |
sed "s~{{libdir}}~$libdir~" |
sed "s~{{sysconfdir}}~$sysconfdir~" |
sed "s~{{make}}~$make~" |
sed "s~{{php5_version}}~$php5_version~" |
sed "s~{{php7_version}}~$php7_version~" > ~/run.sh
chmod +x ~/run.sh
~/run.sh
