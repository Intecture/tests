#!/bin/sh
# Copyright 2015-2016 Intecture Developers. See the COPYRIGHT file at the
# top-level directory of this distribution and at
# https://intecture.io/COPYRIGHT.
#
# Licensed under the Mozilla Public License 2.0 <LICENSE or
# https://www.tldrlegal.com/l/mpl-2.0>. This file may not be copied,
# modified, or distributed except according to those terms.

# Undefined vars are errors
set -u

# Globals
install_dir="/var/tmp/intecture-tests"
os="{{os}}"
prefix="{{prefix}}"
libdir="{{libdir}}"
sysconfdir="{{sysconfdir}}"
make="{{make}}"
php5_version="{{php5_version}}"
php7_version="{{php7_version}}"

main() {
    mkdir -p $install_dir
    cd $install_dir

    # Build/unit test/install Intecture
    install_api || exit 1
    helper_run intecture agent || exit 1
    helper_run intecture auth || exit 1
    helper_run intecture cli || exit 1

    prepare || exit 1

    # Full stack tests
    run || exit 1

    service inauth stop
    service inagent stop

    remove_api || exit 1
    helper_remove intecture agent || exit 1
    helper_remove intecture auth || exit 1
    helper_remove intecture cli || exit 1
    rm -rf "$sysconfdir/intecture" agent_bootstrap rust php

    local _pkgdir="$(mktemp -d 2>/dev/null || ensure mktemp -d -t intecture)"

    helper_pkg agent $_pkgdir || exit 1
    helper_pkg_install agent $_pkgdir || exit 1
    helper_pkg api $_pkgdir || exit 1
    helper_pkg_install api $_pkgdir || exit 1
    helper_pkg auth $_pkgdir || exit 1
    helper_pkg_install auth $_pkgdir || exit 1
    helper_pkg cli $_pkgdir || exit 1
    helper_pkg_install cli $_pkgdir || exit 1

    rm -rf $_pkgdir

    prepare || exit 1

    # Full stack tests
    run || exit 1
}

prepare() {
    # Create user certificate
    echo -n "Creating user cert..."
    if [ -f "$sysconfdir/intecture/certs/user.crt" ]; then
        echo "ignored"
    else
        inauth_cli user add -s user || return 1
        echo "done"
    fi

    # Make sure systemd is up to date
    if command -v systemctl > /dev/null 2>&1; then
        systemctl daemon-reload
    fi

    # Start Auth daemon
    echo -n "Starting auth daemon..."
    sed 's/7101/7103/' < "$sysconfdir/intecture/auth.json" > auth.json.tmp
    sed 's/7102/7104/' < auth.json.tmp > "$sysconfdir/intecture/auth.json"
    if [ $os = "freebsd" ] && ! $(grep -qs inauth_enable /etc/rc.conf); then
        echo 'inauth_enable="YES"' >> /etc/rc.conf
    fi
    if pgrep inauth; then
        echo -n "restarting..."
        service inauth restart
    else
        service inauth start
    fi
    # Prevent race condition between API clients authenticating and
    # auth handler receiving certs from Publisher.
    sleep 1
    echo "done"

    # Bootstrap Agent
    echo -n "Bootstrapping agent..."
    if [ -d "agent_bootstrap" ]; then
        echo "ignored"
    else
        incli project init agent_bootstrap rust || return 1
        cp user.crt agent_bootstrap/
        cp "$sysconfdir/intecture/auth.crt_public" agent_bootstrap/auth.crt
        cd agent_bootstrap
        sed 's/auth.example.com/localhost/' < project.json |
        sed 's/7101/7103/' |
        sed 's/7102/7104/' > project.json.tmp
        mv project.json.tmp project.json
        incli host add -s localhost || return 1
        cp localhost.crt "$sysconfdir/intecture/agent.crt"
        echo "done"
        cd ..
    fi

    # Start Agent daemon
    echo -n "Starting agent..."
    if [ $os = "freebsd" ] && ! $(grep -qs inagent_enable /etc/rc.conf); then
        echo 'inagent_enable="YES"' >> /etc/rc.conf
    fi
    if pgrep inagent; then
        echo -n "restarting..."
        service inagent restart
    else
        service inagent start
    fi
    echo "done"
}

run() {
    if [ ! -d rust ]; then
        echo -n "Init Rust project..."
        incli project init rust rust || return 1
        cd rust
        echo "done"

        find /vagrant/payloads/rust/ -name Cargo.lock -delete
        cp /vagrant/data.json data/hosts/localhost.json

        # Build one project, then copy target/ to save time
        echo -n "Building initial payload..."
        cp -PR /vagrant/payloads/rust/command payloads/
        incli payload build command || return 1
        echo "done"

        echo -n "Build remaining payloads..."
        cp -PR /vagrant/payloads/rust/data payloads/
        cp -PR payloads/command/target payloads/data/
        cp -PR /vagrant/payloads/rust/directory payloads/
        cp -PR payloads/command/target payloads/directory/
        cp -PR /vagrant/payloads/rust/file payloads/
        cp -PR payloads/command/target payloads/file/
        cp -PR /vagrant/payloads/rust/package payloads/
        cp -PR payloads/command/target payloads/package/
        cp -PR /vagrant/payloads/rust/payload payloads/
        cp -PR payloads/command/target payloads/payload/
        cp -PR /vagrant/payloads/php/payload_nested payloads/
        cp -PR /vagrant/payloads/rust/service payloads/
        cp -PR payloads/command/target payloads/service/
        cp -PR /vagrant/payloads/rust/template payloads/
        cp -PR payloads/command/target payloads/template/
        incli payload build || return 1
        echo "done"

        # Copy this after building, or the build will fail
        cp -PR /vagrant/payloads/php/payload_missingdep payloads/

        sed 's/auth.example.com/localhost/' < project.json |
        sed 's/7101/7103/' |
        sed 's/7102/7104/' > project.json.new
        mv project.json.new project.json
        cp "$install_dir/user.crt" .
        cp "$sysconfdir/intecture/auth.crt_public" auth.crt
        sed "s~intecture-api = .*~intecture-api = { path = \"$install_dir/api\" }~" Cargo.toml > Cargo.toml.new
        mv Cargo.toml.new Cargo.toml

        echo "Run Rust project..."
        incli run localhost || return 1

        cd ..
    fi

    if [ ! -d php ]; then
        echo -n "Init PHP project..."
        incli project init php php || return 1
        cd php
        echo "done"

        cp /vagrant/data.json data/hosts/localhost.json

        echo -n "Build payloads..."
        cp -PR /vagrant/payloads/php/command payloads/
        cp -PR /vagrant/payloads/php/data payloads/
        cp -PR /vagrant/payloads/php/directory payloads/
        cp -PR /vagrant/payloads/php/file payloads/
        cp -PR /vagrant/payloads/php/package payloads/
        cp -PR /vagrant/payloads/php/payload payloads/
        cp -PR /vagrant/payloads/php/payload_nested payloads/
        cp -PR /vagrant/payloads/php/service payloads/
        cp -PR /vagrant/payloads/php/template payloads/
        incli payload build || return 1
        echo "done"

        # Copy this after building, or the build will fail
        cp -PR /vagrant/payloads/php/payload_missingdep payloads/

        sed 's/auth.example.com/localhost/' < project.json |
        sed 's/7101/7103/' |
        sed 's/7102/7104/' > project.json.new
        mv project.json.new project.json
        cp "$install_dir/user.crt" .
        cp "$sysconfdir/intecture/auth.crt_public" auth.crt

        echo "Run PHP project..."
        incli run localhost || return 1

        cd ..
    fi

    echo "ALL TESTS PASSED. RRAAAAAWWWW!";
    cat /vagrant/homer.ascii
}

install_api() {
    echo -n "Run api..."
    helper_copy intecture api || return 0
    helper_make
    helper_make test-local || return 1
    helper_make test-remote || return 1
    helper_make install

    # C binding
    install bindings/c/inapi.h "$prefix/include"

    cd bindings
    local _v="5 7"
    for ver in ${_v}; do
        cp -R "php$ver" "php${ver}_build"
        cd "php${ver}_build"
        helper_make
        helper_make test install || return 1
        cd ..
        rm -rf "php${ver}_build"
    done
    cd ..

    # Create module ini file
    echo 'extension=inapi.so' > ~/.phpenv/versions/$php5_version/etc/conf.d/inapi.ini
    echo 'extension=inapi.so' > ~/.phpenv/versions/$php7_version/etc/conf.d/inapi.ini

    cd ..
    echo "done"
}

remove_api() {
    helper_remove intecture api || exit 1
    rm -f ~/.phpenv/versions/$php5_version/etc/conf.d/inapi.ini
    rm -f ~/.phpenv/versions/$php5_version/lib/php/extensions/debug-non-zts-20131226/inapi.so
    rm -f ~/.phpenv/versions/$php7_version/etc/conf.d/inapi.ini
    rm -f ~/.phpenv/versions/$php7_version/lib/php/extensions/debug-non-zts-20151012/inapi.so
}

helper_copy() {
    if [ -d "$install_dir/$2" ]; then
        echo "ignored"
        return 1
    else
        cp -PR "/$1/$2" "$install_dir/$2" || exit 1
        cd "$install_dir/$2"

        # Remove target/ for Cargo projects to prevent explosions
        if [ -f Cargo.toml ]; then
            rm -rf target
        fi
    fi
}

helper_make() {
    if [ -f config.m4 ]; then
        if [ $# -eq 0 ]; then
            phpize
            ./configure --prefix=$prefix --libdir=$libdir --sysconfdir=$sysconfdir
            $make
        fi

        for arg in "$@"; do
            if test $arg = "test"; then
                TEST_PHP_ARGS="-q" $make test
            else
                $make $arg
            fi
        done
    elif [ -f Makefile ]; then
        if [ $# -eq 0 ]; then
            $make TARGET=debug PREFIX=$prefix LIBDIR=$libdir SYSCONFDIR=$sysconfdir
        fi

        for arg in "$@"; do
            $make TARGET=debug PREFIX=$prefix LIBDIR=$libdir SYSCONFDIR=$sysconfdir $arg
        done
    fi
}

helper_run() {
    echo -n "Run $2..."
    helper_copy "$1" "$2" || return 0
    helper_make
    helper_make test install || return 1
    cd "$install_dir"
    echo "done"
}

helper_remove() {
    echo -n "Remove $2..."
    cd "$install_dir/$2"
    helper_make uninstall || return 1
    cd ..
    echo "done"
}

helper_pkg() {
    echo -n "Pkg $1..."
    cd "$install_dir/$1"

    ./package.sh || return 1

    cp ".pkg/$os/$(ls .pkg/$os/ | sort -nr | head -1)" "$2/$1.tar.bz2"

    cd "$install_dir"
    echo "done"
}

helper_pkg_install() {
    curl -sSf https://get.intecture.io | sh -s -- -y -d $2 $1
}

main "$@"
