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
        yum -y install centos-release-scl
        yum -y install devtoolset-3-toolchain git libtool glib* curl-devel zlib-devel openssl-devel wget cmake libunwind-devel

        # Enable devtoolset
        echo '. /opt/rh/devtoolset-3/enable' >> ~/.bashrc
        # Set MANPATH to avoid undefined var errors
        export MANPATH=""
        . /opt/rh/devtoolset-3/enable

        # Upgrade version of autoconf
        wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
        tar xvfvz autoconf-2.69.tar.gz
        cd autoconf-2.69
        ./configure --prefix=$prefix --libdir=$libdir
        make && make install
        ;;

    centos7 )
        os="redhat"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib64"

        yum update -y
        yum -y install git libtool gcc-c++ glib* curl-devel zlib-devel openssl-devel wget cmake libunwind-devel

        # Upgrade version of autoconf
        wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
        tar xvfvz autoconf-2.69.tar.gz
        cd autoconf-2.69
        ./configure --prefix=$prefix --libdir=$libdir
        make && make install
        ;;

    debian )
        os="debian"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib"

        apt-get update
        apt-get -y install git build-essential libtool pkg-config curl wget cmake automake autoconf libunwind-dev libssl-dev
        ;;

    fedora )
        os="redhat"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib64"

        dnf update -y
        dnf -y install git libtool gcc-c++ glib* curl-devel zlib-devel openssl-devel wget cmake libunwind-devel
        ;;

    freebsd )
        os="freebsd"
        prefix="/usr/local"
        libdir="$prefix/lib"
        sysconfdir="$prefix/etc"
        make="gmake"

        export LIBRARY_PATH="$libdir"
        export PKG_CONFIG_PATH="$libdir/pkgconfig"

        pkg update -f && pkg check -Ba
        pkg upgrade -y
        pkg install -y git libtool gcc glib gmake automake autoconf pkgconf curl gnupg wget cmake bash re2c bison openssl-devel
        ;;

    ubuntu )
        os="debian"
        prefix="/usr"
        sysconfdir="/etc"
        libdir="$prefix/lib"

        apt-get update
        apt-get -y install git build-essential libtool pkg-config curl wget cmake automake autoconf libunwind8-dev libssl-dev
        ;;
esac

cd /var/tmp

# Install ZMQ
if [ ! -d zeromq-4.2.0 ]; then
    curl -sSOL https://github.com/zeromq/libzmq/releases/download/v4.2.0/zeromq-4.2.0.tar.gz
    tar zxf zeromq-4.2.0.tar.gz
    cd zeromq-4.2.0

    # XXX There is a bug when linking libunwind on some platforms.
    # Until a new release is made containing this patch, we have to
    # apply it manually.
    git apply /vagrant/configure.ac.patch

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

# Run these manually instead of sourcing .bashrc as .bashrc is only
# intended for interactive shells
export PHPENV_ROOT="/root/.phpenv"
export PATH="${PHPENV_ROOT}/bin:${PATH}"
eval "$(phpenv init -)"

sed -i -s 's/\.rbenv-version/.phpenv-version/g' "$PHPENV_ROOT"/libexec/rbenv-local
sed -i -s 's/\.rbenv-version/.phpenv-version/g' "$PHPENV_ROOT"/libexec/rbenv-version-file
sed -i -s 's/\.ruby-version/.php-version/g' "$PHPENV_ROOT"/libexec/rbenv-local
sed -i -s 's/\.ruby-version/.php-version/g' "$PHPENV_ROOT"/libexec/rbenv-version-file
sed -i -e 's/\(^\|[^/]\)rbenv/\1phpenv/g' "$PHPENV_ROOT"/libexec/rbenv-init
sed -i -e 's/\phpenv-commands/rbenv-commands/g' "$PHPENV_ROOT"/libexec/rbenv-init
sed -i -e 's/\Ruby/PHP/g' "$PHPENV_ROOT"/libexec/rbenv-which

cat << "EOF" > ~/.phpenv/plugins/php-build/share/php-build/default_configure_options
--disable-all
--enable-debug
--without-pear
EOF

phpbuild_dir="$PHPENV_ROOT/plugins/php-build/share/php-build"

# These files are found by FreeBSD `ls`, causing explosions
rm -f "$phpbuild_dir/after-install.d/.empty"
rm -f "$phpbuild_dir/before-install.d/.empty"

# Don't install XDEBUG!
sed 's/install_xdebug.*//' < "$phpbuild_dir/definitions/$php5_version" > "$phpbuild_dir/definitions/$php5_version.new"
mv "$phpbuild_dir/definitions/$php5_version.new" "$phpbuild_dir/definitions/$php5_version"
sed 's/install_xdebug.*//' < "$phpbuild_dir/definitions/$php7_version" > "$phpbuild_dir/definitions/$php7_version.new"
mv "$phpbuild_dir/definitions/$php7_version.new" "$phpbuild_dir/definitions/$php7_version"

phpenv install $php5_version
rm -rf /tmp/php-build

phpenv install $php7_version
rm -rf /tmp/php-build

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
