<?php

use Intecture\Directory;
use Intecture\Telemetry;

class DirectoryTest implements Testable {
    public static function test($host) {
        $tempdir = tempnam(sys_get_temp_dir(), '');
        unlink($tempdir);
        mkdir($tempdir);

        $telemetry = Telemetry::load($host);
        $tdata = $telemetry->get();

        $dir = new Directory($host, $tempdir . '/path/to/dir');
        assert(!$dir->exists($host));

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
        assert($owner['group_name'] == ($tdata['os']['platform'] == "freebsd" ? 'wheel' : 'root'));
        assert($owner['group_gid'] == 0);

        $dir->set_owner($host, 'vagrant', 'vagrant');
        $new_owner = $dir->get_owner($host);
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

        assert($dir->get_mode($host) == 755);
        $dir->set_mode($host, 777);
        assert($dir->get_mode($host) == 777);

        $out = $exit = NULL;
        exec("touch $tempdir/path/to/mv_dir/test", $out, $exit);
        assert($exit == 0);
        $dir->delete($host, array(Directory::OPT_DO_RECURSIVE));
        $out = $exit = NULL;
        exec("ls $tempdir/path/to/mv_dir 2>&1", $out, $exit);
        assert($exit == ($tdata['os']['platform'] == 'freebsd' ? 1 : 2));

        rmdir("$tempdir/path/to");
        rmdir("$tempdir/path");
        rmdir($tempdir);
    }
}
