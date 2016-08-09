<?php

use Intecture\Host;
use Intecture\Package;
use Intecture\PackageResult;
use Intecture\Providers;
use Intecture\Telemetry;

class PackageTest implements Testable {
    public static function test($host) {
        $telemetry = Telemetry::load($host);
        $tdata = $telemetry->get();

        if ($tdata['os']['platform'] == 'centos') {
            $epel_pkg = new Package($host, 'epel-release');
            $result = $epel_pkg->install($host);
            if ($result !== NULL) {
                assert($result['exit_code'] == 0);
            }
        }

        $pkg = new Package($host, "nginx");
        assert(!$pkg->is_installed());

        $result = $pkg->install($host);
        if ($result === NULL) {
            echo 'Didn\'t install package';
            exit(1);
        } else {
            assert($result['exit_code'] == 0);
        }

        $result = $pkg->install($host);
        if ($result !== NULL) {
            echo 'Tried to install package again';
            exit(1);
        }

        assert($pkg->is_installed());

        $result = $pkg->uninstall($host);
        if ($result === NULL) {
            echo 'Didn\'t uninstall package';
            exit(1);
        } else {
            assert($result['exit_code'] == 0);
        }

        $result = $pkg->uninstall($host);
        if ($result !== NULL) {
            echo 'Tried to uninstall package again';
            exit(1);
        }

        assert(!$pkg->is_installed());

        switch ($tdata['os']['platform']) {
            case 'centos':
                $provider = Package::PROVIDER_YUM;
                break;
            case 'debian':
            case 'ubuntu':
                $provider = Package::PROVIDER_APT;
                break;
            case 'fedora':
                $provider = Package::PROVIDER_DNF;
                break;
            case 'freebsd':
                $provider = Package::PROVIDER_PKG;
                break;
            case 'macos':
                $provider = Package::PROVIDER_HOMEBREW;
                break;
        }

        $pkg = new Package($host, 'nginx', $provider);
        assert(!$pkg->is_installed());
    }
}
