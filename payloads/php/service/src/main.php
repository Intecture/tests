<?php

use Intecture\Host;
use Intecture\Package;
use Intecture\Service;
use Intecture\ServiceRunnable;

assert_options(ASSERT_ACTIVE, true);
assert_options(ASSERT_BAIL, true);

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

if ($host->data()['_telemetry']['os']['platform'] == 'centos') {
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
$out = $exit = NULL;
exec($host->data()['service']['check_on'], $out, $exit);
assert($exit == 0);

assert($svc->action($host, 'map-enable') === NULL);

$result = $svc->action($host, 'start');
if ($result !== NULL) {
    assert($result['exit_code'] == 0);
}
$out = $exit = NULL;
exec('pgrep nginx', $out, $exit);
assert($exit == 0);

assert($svc->action($host, 'start') === NULL);

$result = $svc->action($host, 'stop');
assert($result['exit_code'] == 0);
$out = $exit = NULL;
exec('pgrep nginx', $out, $exit);
assert($exit == 1);

assert($svc->action($host, 'stop') === NULL);

$result = $svc->action($host, 'disable');
assert($result['exit_code'] == 0);
$out = $exit = NULL;
exec($host->data()['service']['check_off'], $out, $exit);
assert($exit == $host->data()['service']['check_off_expect']);

assert($svc->action($host, 'disable') === NULL);

$result = $pkg->uninstall($host);
assert($result['exit_code'] == 0);
