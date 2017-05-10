<?php

use Intecture\Host;

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);
$data = $host->data();

// Local data
actually_bloody_assert($data['data']['null'], NULL);
actually_bloody_assert($data['data']['bool'], true);
actually_bloody_assert($data['data']['int'], -123);
actually_bloody_assert($data['data']['double'], 1.1);
actually_bloody_assert($data['data']['str'], 'This is a string');
actually_bloody_assert($data['data']['array'][0], 1);
actually_bloody_assert($data['data']['array'][1], 'two');
actually_bloody_assert($data['data']['array'][2], 3);
actually_bloody_assert($data['data']['obj']['nested'], 'Boo!');

// Telemetry data
$out = $exit = NULL;
$hostname = exec('hostname', $out, $exit);
actually_bloody_assert($exit, 0);
actually_bloody_assert($data['_telemetry']['hostname'], $hostname);

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
