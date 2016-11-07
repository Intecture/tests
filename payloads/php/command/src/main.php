<?php

use Intecture\Command;
use Intecture\Host;

assert_options(ASSERT_ACTIVE, true);
assert_options(ASSERT_BAIL, true);

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

$whoami = new Command($host->data()['command']['cmd']);
$result = $whoami->exec($host);
assert($result['exit_code'] == 0);
assert($result['stdout'] == 'root');
assert($result['stderr'] == '');
