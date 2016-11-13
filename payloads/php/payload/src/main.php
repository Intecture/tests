<?php

use Intecture\Host;
use Intecture\Payload;
use Intecture\PayloadException;

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

echo 'Test running nested payload...';
$payload = new Payload('payload_nested::my_controller');
$payload->run($host, [ 'myarg' ]);
echo 'done', PHP_EOL;

echo 'Test missing deps payload...';
try {
    $fail = false;
    $payload = new Payload('payload_missingdep');
} catch (PayloadException $e) {
    $fail = true;
} finally {
    actually_bloody_assert($fail, true);
}
echo 'done', PHP_EOL;

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
