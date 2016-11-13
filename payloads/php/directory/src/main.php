<?php

use Intecture\Directory;
use Intecture\DirectoryException;
use Intecture\Host;

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

$tempdir = tempnam(sys_get_temp_dir(), '');
unlink($tempdir);
mkdir($tempdir);

try {
    $e = false;
    new Directory($host, '/etc/hosts');
} catch (DirectoryException $e) {
    $e = true;
} finally {
    actually_bloody_assert($e, true);
}

$dir = new Directory($host, $tempdir . '/path/to/dir');
actually_bloody_assert($dir->exists($host), false);

try {
    $e = false;
    $dir->create($host);
} catch (DirectoryException $e) {
    $e = true;
} finally {
    actually_bloody_assert($e, true);
}

$dir->create($host, array(Directory::OPT_DO_RECURSIVE));
$out = $exit = NULL;
exec("ls $tempdir/path/to/dir", $out, $exit);
actually_bloody_assert($exit, 0);

$dir->mv($host, $tempdir . '/path/to/mv_dir');
$out = $exit = NULL;
exec("ls $tempdir/path/to/mv_dir", $out, $exit);
actually_bloody_assert($exit, 0);

$owner = $dir->get_owner($host);
actually_bloody_assert($owner['user_name'], 'root');
actually_bloody_assert($owner['user_uid'], 0);
actually_bloody_assert($owner['group_name'], ($host->data()['_telemetry']['os']['platform'] == 'freebsd' ? 'wheel' : 'root'));
actually_bloody_assert($owner['group_gid'], 0);

$dir->set_owner($host, 'vagrant', 'vagrant');
$new_owner = $dir->get_owner($host);
actually_bloody_assert($new_owner['user_name'], 'vagrant');
actually_bloody_assert($new_owner['group_name'], 'vagrant');
actually_bloody_assert($new_owner['user_uid'], $host->data()['file']['file_owner']);
actually_bloody_assert($new_owner['group_gid'], $host->data()['file']['file_owner']);

actually_bloody_assert($dir->get_mode($host), 755);
$dir->set_mode($host, 777);
actually_bloody_assert($dir->get_mode($host), 777);

$out = $exit = NULL;
exec("touch $tempdir/path/to/mv_dir/test", $out, $exit);
actually_bloody_assert($exit, 0);

try {
    $e = false;
    $dir->delete($host);
} catch (DirectoryException $e) {
    $e = true;
} finally {
    actually_bloody_assert($e, true);
}

$dir->delete($host, array(Directory::OPT_DO_RECURSIVE));
$out = $exit = NULL;
exec("ls $tempdir/path/to/mv_dir 2>&1", $out, $exit);
actually_bloody_assert($exit, ($host->data()['_telemetry']['os']['platform'] == 'freebsd' ? 1 : 2));

rmdir("$tempdir/path/to");
rmdir("$tempdir/path");
rmdir($tempdir);

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
