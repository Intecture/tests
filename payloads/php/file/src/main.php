<?php

use Intecture\File;
use Intecture\FileException;
use Intecture\Host;

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

try {
    $e = false;
    new File($host, "/etc");
} catch (FileException $e) {
    $e = true;
} finally {
    assert($e);
}

$file = new File($host, $tempdir . '/remote');
assert(!$file->exists($host));

$out = $exit = NULL;
exec("dd bs=1024 if=/dev/urandom of=$tempdir/local count=1024 2>&1", $out, $exit);
assert($exit == 0);
$file->upload($host, "$tempdir/local");
assert($file->exists($host));
$out = $exit = NULL;
exec("ls $tempdir/remote", $out, $exit);
assert($exit == 0);

$file->upload($host, "$tempdir/local", array(File::OPT_BACKUP_EXISTING => "_bk"));
$out = $exit = NULL;
exec("ls $tempdir/remote_bk", $out, $exit);
assert($exit == 0);

$file->mv($host, "$tempdir/mv_file");
$out = $exit = NULL;
exec("ls $tempdir/mv_file", $out, $exit);
assert($exit == 0);
exec("ls $tempdir/remote 2>&1", $out, $exit);
assert($exit != 0);

$file->copy($host, "$tempdir/cp_file");
exec("ls $tempdir/mv_file", $out, $exit);
assert($exit == 0);
exec("ls $tempdir/cp_file", $out, $exit);
assert($exit == 0);

$owner = $file->get_owner($host);
assert($owner['user_name'] == 'root');
assert($owner['user_uid'] == 0);
assert($owner['group_name'] == ($host->data()['_telemetry']['os']['platform'] == "freebsd" ? 'wheel' : 'root'));
assert($owner['group_gid'] == 0);

$file->set_owner($host, 'vagrant', 'vagrant');
$new_owner = $file->get_owner($host);
assert($new_owner['user_name'] == 'vagrant');
assert($new_owner['group_name'] == 'vagrant');
assert($new_owner['user_uid'] == $host->data()['file']['file_owner']);
assert($new_owner['group_gid'] == $host->data()['file']['file_owner']);

assert($file->get_mode($host) == 644);
$file->set_mode($host, 777);
assert($file->get_mode($host) == 777);

$file->delete($host);
$out = $exit = NULL;
exec("ls $tempdir/mv_path 2>&1", $out, $exit);
assert($exit == ($host->data()['_telemetry']['os']['platform'] == 'freebsd' ? 1 : 2));

unlink("$tempdir/local");
unlink("$tempdir/cp_file");
unlink("$tempdir/remote_bk");
rmdir($tempdir);
