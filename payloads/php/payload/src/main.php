<?php

use Intecture\Host;
use Intecture\Payload;
use Intecture\PayloadException;

assert_options(ASSERT_ACTIVE, true);
assert_options(ASSERT_BAIL, true);

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

echo 'Test running nested payload...';
$payload = new Payload('payload_nested::my_controller', [ "myarg" ]);
$payload->run($host);
echo 'done', PHP_EOL;

echo 'Test missing deps payload...';
try {
    $fail = false;
    $payload = new Payload('payload_missingdep');
} catch (PayloadException $e) {
    $fail = true;
} finally {
    assert($fail);
}
echo 'done', PHP_EOL;
