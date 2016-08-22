<?php

use Intecture\Package;
use Intecture\Service;
use Intecture\ServiceRunnable;
use Intecture\Telemetry;

class ServiceTest implements Testable {
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

        $pkg = new Package($host, 'nginx');
        $result = $pkg->install($host);
        if ($result !== NULL) {
            assert($result['exit_code'] == 0);
        }

        $runnable = new ServiceRunnable('nginx', ServiceRunnable::SERVICE);
        $svc = new Service($runnable, array('map-enable' => 'enable'));

        $result = $svc->action($host, 'map-enable');
        if ($result !== NULL) {
            assert($result['exit_code'] == 0);
        }
        $cmd = '';
        $out = $exit = NULL;
        switch ($tdata['os']['platform']) {
            case 'centos':
                $cmd = "chkconfig|egrep -qs 'nginx.+3:on'";
                break;
            case 'fedora':
                $cmd = "systemctl list-unit-files|egrep -qs 'nginx.service.+enabled'";
                break;
            case 'debian':
            case 'ubuntu':
                $cmd = "ls /etc/rc3.d|egrep -qs 'S[0-9]+nginx'";
                break;
            case 'freebsd':
                $cmd = 'grep -qs \'nginx_enable="YES"\' /etc/rc.conf';
                break;
            default:
                fwrite(STDERR, 'Unknown platform');
                exit(1);
        }
        $check_enable = exec($cmd, $out, $exit);
        assert($exit == 0);

        assert($svc->action($host, 'map-enable') === NULL);

        $result = $svc->action($host, 'start');
        if ($result !== NULL) {
            assert($result['exit_code'] == 0);
        }
        $out = $exit = NULL;
        $check_start = exec('pgrep nginx', $out, $exit);
        assert($exit == 0);

        assert($svc->action($host, 'start') === NULL);

        $result = $svc->action($host, 'stop');
        assert($result['exit_code'] == 0);
        $out = $exit = NULL;
        $check_start = exec('pgrep nginx', $out, $exit);
        assert($exit == 1);

        assert($svc->action($host, 'stop') === NULL);

        $result = $svc->action($host, 'disable');
        assert($result['exit_code'] == 0);
        $cmd = '';
        $out = $exit = NULL;
        $expect = 0;
        switch ($tdata['os']['platform']) {
            case 'centos':
                $cmd = "chkconfig|egrep -qs 'nginx.+3:off'";
                break;
            case 'fedora':
                $cmd = "systemctl list-unit-files|egrep -qs 'nginx.service.+disabled'";
                break;
            case 'debian':
            case 'ubuntu':
                $cmd = "ls /etc/rc3.d|egrep -qs 'S[0-9]+nginx'";
                $expect = 1;
                break;
            case 'freebsd':
                $cmd = 'grep -qs \'nginx_enable="YES"\' /etc/rc.conf';
                $expect = 1;
                break;
            default:
                fwrite(STDERR, 'Unknown platform');
                exit(1);
        }
        $check_enable = exec($cmd, $out, $exit);
        assert($exit == $expect);

        assert($svc->action($host, 'disable') === NULL);

        $result = $pkg->uninstall($host);
        assert($result['exit_code'] == 0);
    }
}
