<?php

use Intecture\Host;
use Intecture\Package;
use Intecture\Service;
use Intecture\ServiceRunnable;

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

if ($host->data()['_telemetry']['os']['platform'] == 'centos') {
    $epel_pkg = new Package($host, 'epel-release');
    $result = $epel_pkg->install($host);
    if ($result !== NULL) {
        actually_bloody_assert($result['exit_code'], 0);
    }
}

$pkg = new Package($host, 'nginx');
$result = $pkg->install($host);
if ($result !== NULL) {
    actually_bloody_assert($result['exit_code'], 0);
}

$runnable = new ServiceRunnable('nginx', ServiceRunnable::SERVICE);
$svc = new Service($runnable, array('map-enable' => 'enable'));

$result = $svc->action($host, 'map-enable');
if ($result !== NULL) {
    actually_bloody_assert($result['exit_code'], 0);
}
$out = $exit = NULL;
exec($host->data()['service']['check_on'], $out, $exit);
actually_bloody_assert($exit, 0);

actually_bloody_assert($svc->action($host, 'map-enable'), NULL);

$result = $svc->action($host, 'start');
if ($result !== NULL) {
    actually_bloody_assert($result['exit_code'], 0);
}
$out = $exit = NULL;
exec('pgrep nginx', $out, $exit);
actually_bloody_assert($exit, 0);

actually_bloody_assert($svc->action($host, 'start'), NULL);

$result = $svc->action($host, 'stop');
actually_bloody_assert($result['exit_code'], 0);
$out = $exit = NULL;
exec('pgrep nginx', $out, $exit);
actually_bloody_assert($exit, 1);

actually_bloody_assert($svc->action($host, 'stop'), NULL);

$result = $svc->action($host, 'disable');
actually_bloody_assert($result['exit_code'], 0);
$out = $exit = NULL;
exec($host->data()['service']['check_off'], $out, $exit);
actually_bloody_assert($exit, $host->data()['service']['check_off_expect']);

actually_bloody_assert($svc->action($host, 'disable'), NULL);

$result = $pkg->uninstall($host);
actually_bloody_assert($result['exit_code'], 0);

function actually_bloody_assert($v1, $v2, $ne = false) {
    if (!$ne && $v1 !== $v2) {
        echo "Failed assertion: $v1 === $v2", PHP_EOL;
        exit(1);
    }
    else if ($ne && $v1 === $v2) {
        echo "Failed assertion: $v1 !== $v2", PHP_EOL;
        exit(1);
    }
}
