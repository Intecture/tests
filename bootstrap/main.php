<?php

use Intecture\Host;

$host = Host::connect_endpoint($argv[1], 7101, 7102);
$os = $host->data()['_telemetry']['os'];

switch ($argv[2]) {
    case 'centos6':
    case 'centos7':
        $test_os = 'centos';
        break;

    default:
        $test_os = $argv[2];
}

if ($os['platform'] != $test_os) {
    echo 'Expected platform "' . $test_os . '", got "' . $os['platform'] . '"', PHP_EOL;
    exit(1);
} else {
    echo 'Ok!', PHP_EOL;
    print_r($os);
}
