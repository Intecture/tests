<?php

use Intecture\Command;
use Intecture\Host;

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

$whoami = new Command($host->data()['command']['cmd']);
$result = $whoami->exec($host);
actually_bloody_assert($result['exit_code'], 0);
actually_bloody_assert($result['stdout'], 'root');
actually_bloody_assert($result['stderr'], '');

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
