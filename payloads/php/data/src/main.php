<?php

use Intecture\Host;

assert_options(ASSERT_ACTIVE, true);
assert_options(ASSERT_BAIL, true);

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

echo 'Connecting to host...';
$host = Host::connect_payload($argv[1], $argv[2]);
echo 'done', PHP_EOL;

$data = $host->data();

// Local data
assert($data['data']['null'] === NULL);
assert($data['data']['bool'] === true);
assert($data['data']['int'] === -123);
assert($data['data']['double'] === 1.1);
assert($data['data']['str'] === 'This is a string');
assert($data['data']['array'][0] === 1);
assert($data['data']['array'][1] === "two");
assert($data['data']['array'][2] === 3);
assert($data['data']['obj']['nested'] === "Boo!");

// Telemetry data
$out = $exit = NULL;
$hostname = exec('hostname -f', $out, $exit);
assert($exit == 0);
assert($data['_telemetry']['hostname'] == $hostname);
