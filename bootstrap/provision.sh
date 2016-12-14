#!/bin/sh

set -u

os=$1
myaddr=$2
hostname=$3
hostaddr=$4
sysconfdir=

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

    debian | ubuntu )
        sysconfdir=/etc
        apt-get install -y php git
        ;;

    freebsd )
        sysconfdir=/usr/local/etc
        pkg install -y php56 git
        ;;

    * )
        echo "Unknown OS" >&2
        exit 1
esac

curl -sSf https://get.intecture.io | sh -s -- -y api
curl -sSf https://get.intecture.io | sh -s -- auth
curl -sSf https://get.intecture.io | sh -s -- cli

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
incli host bootstrap "$hostaddr" -u vagrant -i "/vagrant/bootstrap/.vagrant/machines/$hostname/virtualbox/private_key" || exit 1

cp /vagrant/bootstrap/main.php src/
incli run "$hostaddr" "$hostname"
