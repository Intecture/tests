<?php

use Intecture\File;
use Intecture\Telemetry;

class FileTest implements Testable {
    private $host;

    public function test($host) {
        $tempdir = tempnam(sys_get_temp_dir(), '');
        unlink($tempdir);
        mkdir($tempdir);

        $telemetry = Telemetry::load($host);
        $tdata = $telemetry->get();

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
        assert($owner['group_name'] == ($tdata['os']['platform'] == "freebsd" ? 'wheel' : 'root'));
        assert($owner['group_gid'] == 0);

        $file->set_owner($host, 'vagrant', 'vagrant');
        $new_owner = $file->get_owner($host);
        assert($new_owner['user_name'] == 'vagrant');
        assert($new_owner['group_name'] == 'vagrant');

        switch ($tdata['os']['platform']) {
            case 'centos':
                assert($new_owner['user_uid'] == 500);
                assert($new_owner['group_gid'] == 500);
                break;
            case 'debian':
            case 'fedora':
            case 'ubuntu':
                assert($new_owner['user_uid'] == 1000);
                assert($new_owner['group_gid'] == 1000);
                break;
            case 'freebsd':
                assert($new_owner['user_uid'] == 1001);
                assert($new_owner['group_gid'] == 1001);
                break;
        }

        assert($file->get_mode($host) == 644);
        $file->set_mode($host, 777);
        assert($file->get_mode($host) == 777);

        $file->delete($host);
        $out = $exit = NULL;
        exec("ls $tempdir/mv_path 2>&1", $out, $exit);
        assert($exit == ($tdata['os']['platform'] == 'freebsd' ? 1 : 2));

        unlink("$tempdir/local");
        unlink("$tempdir/cp_file");
        unlink("$tempdir/remote_bk");
        rmdir($tempdir);
    }
}
