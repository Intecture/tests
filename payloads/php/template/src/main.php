<?php

use Intecture\File;
use Intecture\Host;
use Intecture\Template;

assert_options(ASSERT_ACTIVE, true);
assert_options(ASSERT_BAIL, true);

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

$tempdir = tempnam(sys_get_temp_dir(), '');
unlink($tempdir);
mkdir($tempdir);

$tpl = new Template("template/tpl/test_conf.tpl");
$fd = $tpl->render([ 'name' => $host->data()['template']['name'] ]);

$filename = $tempdir . '/test_conf.conf';
$expected_content = 'Hello world!';

$file = new File($host, $filename);
$file->upload_file($host, $fd);

$fh = fopen($filename, 'r');
$content = fread($fh, filesize($filename));
fclose($fh);

assert($content == $expected_content);
