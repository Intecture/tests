#!/bin/sh

set -u

os=$1
myaddr=$2
hostname=$3
hostaddr=$4
sysconfdir=
preinstall=

case $os in
    centos6 )
        sysconfdir=/etc
        yum -y install http://rpms.remirepo.net/enterprise/remi-release-6.rpm
        yum -y install yum-utils
        yum-config-manager --enable remi-php70
        yum -y install php git
        ;;

    centos7 )
        sysconfdir=/etc
        yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
        yum -y install yum-utils
        yum-config-manager --enable remi-php70
        yum -y install php git
        ;;

    fedora )
        sysconfdir=/etc
        dnf -y install http://rpms.remirepo.net/fedora/remi-release-24.rpm
        dnf config-manager --set-enabled remi-php70
        dnf -y install php git
        ;;

    debian )
        sysconfdir=/etc
        echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
        echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
        wget https://www.dotdeb.org/dotdeb.gpg
        apt-key add dotdeb.gpg
        apt-get install -y php5 git pkg-config curl
        ;;

    ubuntu )
        sysconfdir=/etc
        add-apt-repository -y ppa:ondrej/php
        apt-get update
        apt-get install -y php5.6 git pkg-config
        ;;

    freebsd )
        sysconfdir=/usr/local/etc
        pkg install -y php56 git
        ;;

    * )
        echo "Unknown OS" >&2
        exit 1
esac

case $hostname in
    debian | ubuntu )
        preinstall="sudo apt-get install -y pkg-config curl"
        ;;

    freebsd )
        preinstall="sudo pkg install -y pkgconf curl"
        ;;
esac

curl -sSf https://get.intecture.io | sh -s -- -y api || exit 1
curl -sSf https://get.intecture.io | sh -s -- auth || exit 1
curl -sSf https://get.intecture.io | sh -s -- cli || exit 1

inauth_cli user add -s user || exit 1

if [ $os = "freebsd" ] && ! $(grep -qs inauth_enable /etc/rc.conf); then
    echo 'inauth_enable="YES"' >> /etc/rc.conf
fi
service inauth start
sleep 1

incli project init bootstrap php || exit 1
cp user.crt bootstrap/
cp "$sysconfdir/intecture/auth.crt_public" bootstrap/auth.crt
cd bootstrap
sed "s/auth.example.com/$myaddr/" < project.json > project.json.tmp
mv project.json.tmp project.json
incli host bootstrap "$hostaddr" -u vagrant -i "/vagrant/bootstrap/.vagrant/machines/$hostname/virtualbox/private_key" -m "$preinstall" || exit 1

cp /vagrant/bootstrap/main.php src/
incli run "$hostaddr" "$hostname"
