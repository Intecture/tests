#include "header.h"
#include <inapi.h>

int directory_test (Host *host) {
    // Create temp dir
    char template[] = "/tmp/tmpdir.XXXXXX";
    char *tmp_dirname = mkdtemp(template);
    assert(tmp_dirname);

    char testpath[30];
    strcpy(testpath, tmp_dirname);
    strcat(testpath, "/path/to/dir");
    char mvpath[33];
    strcpy(mvpath, tmp_dirname);
    strcat(mvpath, "/path/to/mv_dir");
    char touchpath[38];
    strcpy(touchpath, mvpath);
    strcat(touchpath, "/test");

    Telemetry telemetry = telemetry_init(&host);

    Directory dir = directory_new(&host, &testpath);
    assert(!directory_exists(&dir, &host));

    DirectoryOpts opts = { .do_recursive = true };

    directory_create(&dir, &host, &opts);
    assert(directory_exists(&dir, &host));
    char create_check_cmd[33];
    strcpy(create_check_cmd, "ls ");
    strcat(create_check_cmd, testpath);
    int create_check = system(create_check_cmd);
    assert(create_check != -1 && WEXITSTATUS(create_check) == 0);

    directory_mv(&dir, &host, &);
    char mv_check_cmd[36];
    strcpy(mv_check_cmd, "ls ");
    strcat(mv_check_cmd, mvpath);
    int mv_check = system(mv_check_cmd);
    assert(mv_check != -1 && WEXITSTATUS(mv_check) == 0);

    FileOwner owner = directory_get_owner(&dir, &host);
    assert(strcmp(owner.user_name, "root") == 0);
    assert(owner.user_uid == 0);
    if (strcmp(telemetry.os.platform, "freebsd") == 0) {
        assert(strcmp(owner.group_name, "wheel") == 0);
    } else {
        assert(strcmp(owner.group_name, "root") == 0);
    }
    assert(owner.group_gid == 0);

    directory_set_owner(&dir, &host, "vagrant", "vagrant");
    FileOwner new_owner = directory_get_owner(&dir, &host);
    assert(strcmp(new_owner.user_name, "vagrant") == 0);
    assert(strcmp(new_owner.group_name, "vagrant") == 0);
    if (strcmp(telemetry.os.platform, "centos") == 0) {
        assert(new_owner.user_uid == 500);
        assert(new_owner.group_gid == 500);
    }
    else if (strcmp(telemetry.os.platform, "freebsd") == 0) {
        assert(new_owner.user_uid == 1001);
        assert(new_owner.group_gid == 1001);
    } else {
        assert(new_owner.user_uid == 1000);
        assert(new_owner.group_gid == 1000);
    }

    assert(directory_get_mode(&dir, &host) == 755);
    directory_set_mode(&dir, &host, 777);
    assert(directory_get_mode(&dir, &host) == 777);

    char touch_check_cmd[44];
    strcpy(touch_check_cmd, "touch ");
    strcat(touch_check_cmd, touchpath);
    int touch_check = system(touch_check_cmd);
    assert(touch_check != -1 && WEXITSTATUS(touch_check) == 0);

    directory_delete(&dir, &host, &opts);

    char del_check_cmd[36];
    strcpy(del_check_cmd, "ls ");
    strcat(del_check_cmd, mvpath);
    int del_check = system(del_check_cmd);
    if (strcmp(telemetry.os.platform, "freebsd") == 0) {
        assert(del_check != -1 && WEXITSTATUS(del_check) == 1);
    } else {
        assert(del_check != -1 && WEXITSTATUS(del_check) == 2);
    }

    char rm_command[26];
    strncpy (rm_command, "rm -rf ", 7 + 1);
    strncat (rm_command, tmp_dirname, strlen (tmp_dirname) + 1);
    assert(system(rm_command));

    return 0;
}
