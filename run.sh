#!/usr/bin/env sh
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
os=

main() {
    resolve_os

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

    # remove_api || exit 1
    # helper_remove intecture agent || exit 1
    # helper_remove intecture auth || exit 1
    # helper_remove intecture cli || exit 1
    # rm -rf /usr/local/etc/intecture
    # rm -rf "$install_dir/*"
    #
    # helper_pkg intecture agent || exit 1
    # helper_pkg intecture api --with=php || exit 1
    # helper_pkg intecture auth || exit 1
    # helper_pkg intecture cli || exit 1
    #
    # prepare || exit 1
    #
    # # Full stack tests
    # helper_run vagrant rust || exit 1
    # # helper_run vagrant c || exit 1
    # helper_run vagrant php || exit 1
}

prepare() {
    # Create user certificate
    echo -n "Creating user cert..."
    if [ -f "/usr/local/etc/intecture/certs/user.crt" ]; then
        echo "ignored"
    else
        inauth_cli user add -s user || return 1
        echo "done"
    fi

    # Start Auth daemon
    echo -n "Starting auth daemon..."
    sed 's/7101/7103/' </usr/local/etc/intecture/auth.json >auth.json.tmp
    sed 's/7102/7104/' <auth.json.tmp >/usr/local/etc/intecture/auth.json
    if [ $os = "freebsd" ] && ! $(grep -qs inauth_enable /etc/rc.conf); then
        echo 'inauth_enable="YES"' >> /etc/rc.conf
    fi
    if pgrep inauth; then
        echo -n "restarting..."
        service inauth restart
    else
        service inauth start
    fi
    echo "done"

    # Bootstrap Agent
    echo -n "Bootstrapping agent..."
    if [ -d "agent_bootstrap" ]; then
        echo "ignored"
    else
        incli project init agent_bootstrap rust || return 1
        cp user.crt agent_bootstrap/
        cp /usr/local/etc/intecture/auth.crt_public agent_bootstrap/auth.crt
        cd agent_bootstrap
        sed 's/auth.example.com:7101/localhost:7103/' <project.json >project.json.tmp
        mv project.json.tmp project.json
        incli host add -s localhost || return 1
        cp localhost.crt /usr/local/etc/intecture/agent.crt
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

        sed 's/auth.example.com:7101/localhost:7103/' <project.json >project.json.new
        mv project.json.new project.json
        cp "$install_dir/user.crt" .
        cp /usr/local/etc/intecture/auth.crt_public auth.crt
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

        sed 's/auth.example.com:7101/localhost:7103/' <project.json >project.json.new
        mv project.json.new project.json
        cp "$install_dir/user.crt" .
        cp /usr/local/etc/intecture/auth.crt_public auth.crt

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
    install bindings/c/inapi.h /usr/local/include

    # PHP 7 binding
    cd bindings/php7
    helper_make
    helper_make install test || return 1
    cd ../..

    # Create module ini file
    if [ -d /etc/php.d ]; then
        echo 'extension=inapi.so' > /etc/php.d/inapi.ini
    elif [ -d /etc/php7 ]; then
        echo 'extension=inapi.so' > /etc/php7/mods-available/inapi.ini
        ln -s /etc/php7/mods-available/inapi.ini /etc/php7/cli/conf.d/20-inapi.ini
    elif [ -d /etc/php ]; then
        echo 'extension=inapi.so' > /etc/php/7.0/mods-available/inapi.ini
        ln -s /etc/php/7.0/mods-available/inapi.ini /etc/php/7.0/cli/conf.d/20-inapi.ini
    elif [ -f /usr/local/etc/php/extensions.ini ]; then
        echo 'extension=inapi.so' >> /usr/local/etc/php/extensions.ini
    elif [ -f /usr/local/etc/php.ini ]; then
        echo "extension=inapi.so" >> /usr/local/etc/php.ini
    fi

    cd ..
    echo "done"
}

remove_api() {
    helper_remove intecture api || exit 1

    find / -name inapi.so -exec rm -f {} \;
    rm -f /usr/local/include/inapi.h

    if [ -d /etc/php.d ]; then
        rm -f /etc/php.d/inapi.ini
    elif [ -d /etc/php7 ]; then
        rm -f /etc/php7/mods-available/inapi.ini /etc/php7/cli/conf.d/20-inapi.ini
    elif [ -f /usr/local/etc/php/extensions.ini ]; then
        sed 's/extension=inapi.so//' </usr/local/etc/php/extensions.ini >extensions.ini.new
        mv extensions.ini.new /usr/local/etc/php/extensions.ini
    elif [ -f /usr/local/etc/php.ini ]; then
        sed 's/extension=inapi.so//' </usr/local/etc/php.ini >php.ini.new
        mv php.ini.new /usr/local/etc/php.ini
    fi
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
    local _make

    if test $os = "freebsd"; then
        _make="gmake"
    else
        _make="make"
    fi

    if [ -f config.m4 ]; then
        if [ $# -eq 0 ]; then
            phpize
            if test $os = "freebsd"; then
                ./configure CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" --prefix=/usr/local
            else
                ./configure --prefix=/usr/local
            fi
            $_make
        fi

        for arg in "$@"; do
            if test $arg = "test"; then
                TEST_PHP_ARGS="-q" $_make test
            else
                $_make $arg
            fi
        done
    elif [ -f Makefile ]; then
        if [ $# -eq 0 ]; then
            $_make TARGET=debug
        fi

        for arg in "$@"; do
            $_make TARGET=debug $arg
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
    cd "$install_dir"
    rm -rf "$install_dir/$2"
    echo "done"
}

helper_pkg() {
    echo -n "Pkg $2..."
    helper_copy "$1" "$2" || return 0

    local _target
    if test $os = "freebsd"; then
        _target="unknown-freebsd"
    elif test $os = "macos"; then
        _target="apple-darwin"
    else
        _target="unknown-linux-gnu"
    fi

    if [ ! -f /usr/local/bin/bucket ]; then
        curl -sSfL "https://static.rust-bucket.io/x86_64-$_target/latest" -o /usr/local/bin/bucket
        chmod +x /usr/local/bin/bucket
    fi

    bucket install ".bucket/$1-$2_x86_64-$_target.pkg" --with=php || return 1
    cd "$install_dir"
    echo "done"
}

resolve_os() {
    # Fedora
    if $(grep -qs Fedora /etc/redhat-release); then
        os=fedora
        HlEscape="\e"

    # RedHat
    elif $(ls /etc/redhat-release > /dev/null 2>&1); then
        os=redhat
        HlEscape="\e"

    # Debian
    elif $(ls /etc/debian_version > /dev/null 2>&1); then
        os=debian
        HlEscape="\e"

    # macOS
    elif test $(uname -s 2>&1) = "Darwin"; then
        os=macos
        HlEscape="\e"

    # BSD
    elif test $(uname -s 2>&1) = "FreeBSD"; then
        os=freebsd
        HlEscape="\033"

    else
        echo_err "Unknown OS"
        exit 1
    fi
}

main "$@"
