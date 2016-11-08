<?php

use Intecture\Command;
use Intecture\Host;
use Intecture\Payload;

assert_options(ASSERT_ACTIVE, true);
assert_options(ASSERT_BAIL, true);

if ($argc < 3) {
    echo 'Missing args', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

assert($argv[3] == 'myarg');

$whoami = new Command($host->data()['cmd']);
$result = $whoami->exec($host);
assert($result['exit_code'] == 0);
assert($result['stdout'] == 'root');
assert($result['stderr'] == '');
