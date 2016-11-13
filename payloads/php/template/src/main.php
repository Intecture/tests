<?php

use Intecture\File;
use Intecture\Host;
use Intecture\Template;

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

$tempdir = tempnam(sys_get_temp_dir(), '');
unlink($tempdir);
mkdir($tempdir);

$tpl = new Template("payloads/template/tpl/test_conf.tpl");
$fd = $tpl->render([ 'name' => $host->data()['template']['name'] ]);

$filename = $tempdir . '/test_conf.conf';
$file = new File($host, $filename);
$file->upload_file($host, $fd);

$fh = fopen($filename, 'r');
$content = trim(fread($fh, filesize($filename)));
fclose($fh);

actually_bloody_assert($content, 'Hello world!');

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
