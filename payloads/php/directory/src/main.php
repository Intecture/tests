<?php

use Intecture\Directory;
use Intecture\DirectoryException;
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

$tempdir = tempnam(sys_get_temp_dir(), '');
unlink($tempdir);
mkdir($tempdir);

try {
    $e = false;
    new Directory($host, "/etc/hosts");
} catch (DirectoryException $e) {
    $e = true;
} finally {
    assert($e);
}

$dir = new Directory($host, $tempdir . '/path/to/dir');
assert(!$dir->exists($host));

try {
    $e = false;
    $dir->create($host);
} catch (DirectoryException $e) {
    $e = true;
} finally {
    assert($e);
}

$dir->create($host, array(Directory::OPT_DO_RECURSIVE));
$out = $exit = NULL;
exec("ls $tempdir/path/to/dir", $out, $exit);
assert($exit == 0);

$dir->mv($host, $tempdir . '/path/to/mv_dir');
$out = $exit = NULL;
exec("ls $tempdir/path/to/mv_dir", $out, $exit);
assert($exit == 0);

$owner = $dir->get_owner($host);
assert($owner['user_name'] == 'root');
assert($owner['user_uid'] == 0);
assert($owner['group_name'] == ($host->data()['_telemetry']['os']['platform'] == "freebsd" ? 'wheel' : 'root'));
assert($owner['group_gid'] == 0);

$dir->set_owner($host, 'vagrant', 'vagrant');
$new_owner = $dir->get_owner($host);
assert($new_owner['user_name'] == 'vagrant');
assert($new_owner['group_name'] == 'vagrant');
assert($new_owner['user_uid'] == $host->data()['file']['file_owner']);
assert($new_owner['group_gid'] == $host->data()['file']['file_owner']);

assert($dir->get_mode($host) == 755);
$dir->set_mode($host, 777);
assert($dir->get_mode($host) == 777);

$out = $exit = NULL;
exec("touch $tempdir/path/to/mv_dir/test", $out, $exit);
assert($exit == 0);

try {
    $e = false;
    $dir->delete($host);
} catch (DirectoryException $e) {
    $e = true;
} finally {
    assert($e);
}

$dir->delete($host, array(Directory::OPT_DO_RECURSIVE));
$out = $exit = NULL;
exec("ls $tempdir/path/to/mv_dir 2>&1", $out, $exit);
assert($exit == ($host->data()['_telemetry']['os']['platform'] == 'freebsd' ? 1 : 2));

rmdir("$tempdir/path/to");
rmdir("$tempdir/path");
rmdir($tempdir);
