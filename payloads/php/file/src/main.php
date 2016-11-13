<?php

use Intecture\File;
use Intecture\FileException;
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
    new File($host, "/etc");
} catch (FileException $e) {
    $e = true;
} finally {
    actually_bloody_assert($e, true);
}

$file = new File($host, $tempdir . '/remote');
actually_bloody_assert($file->exists($host), false);

$out = $exit = NULL;
exec("dd bs=1024 if=/dev/urandom of=$tempdir/local count=1024 2>&1", $out, $exit);
actually_bloody_assert($exit, 0);
$file->upload($host, "$tempdir/local");
actually_bloody_assert($file->exists($host), true);
$out = $exit = NULL;
exec("ls $tempdir/remote", $out, $exit);
actually_bloody_assert($exit, 0);

$file->upload($host, "$tempdir/local", array(File::OPT_BACKUP_EXISTING => "_bk"));
$out = $exit = NULL;
exec("ls $tempdir/remote_bk", $out, $exit);
actually_bloody_assert($exit, 0);

$file->mv($host, "$tempdir/mv_file");
$out = $exit = NULL;
exec("ls $tempdir/mv_file", $out, $exit);
actually_bloody_assert($exit, 0);
exec("ls $tempdir/remote 2>&1", $out, $exit);
actually_bloody_assert($exit, 0, true);

$file->copy($host, "$tempdir/cp_file");
exec("ls $tempdir/mv_file", $out, $exit);
actually_bloody_assert($exit, 0);
exec("ls $tempdir/cp_file", $out, $exit);
actually_bloody_assert($exit, 0);

$owner = $file->get_owner($host);
actually_bloody_assert($owner['user_name'], 'root');
actually_bloody_assert($owner['user_uid'], 0);
actually_bloody_assert($owner['group_name'], ($host->data()['_telemetry']['os']['platform'] == "freebsd" ? 'wheel' : 'root'));
actually_bloody_assert($owner['group_gid'], 0);

$file->set_owner($host, 'vagrant', 'vagrant');
$new_owner = $file->get_owner($host);
actually_bloody_assert($new_owner['user_name'], 'vagrant');
actually_bloody_assert($new_owner['group_name'], 'vagrant');
actually_bloody_assert($new_owner['user_uid'], $host->data()['file']['file_owner']);
actually_bloody_assert($new_owner['group_gid'], $host->data()['file']['file_owner']);

actually_bloody_assert($file->get_mode($host), 644);
$file->set_mode($host, 777);
actually_bloody_assert($file->get_mode($host), 777);

$file->delete($host);
$out = $exit = NULL;
exec("ls $tempdir/mv_path 2>&1", $out, $exit);
actually_bloody_assert($exit, ($host->data()['_telemetry']['os']['platform'] == 'freebsd' ? 1 : 2));

unlink("$tempdir/local");
unlink("$tempdir/cp_file");
unlink("$tempdir/remote_bk");
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
