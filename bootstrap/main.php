<?php

use Intecture\Host;

$host = Host::connect_endpoint($argv[1], 7101, 7102);
$os = $host->data()['_telemetry']['os'];

if ($os['platform'] != $argv[2]) {
    echo 'Expected platform "' . $argv[2] . '", got "' . $os['platform'] . '"', PHP_EOL;
    exit(1);
} else {
    echo 'Ok!', PHP_EOL;
    print_r($os);
}
