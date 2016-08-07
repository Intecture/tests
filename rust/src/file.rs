use inapi::{File, FileOptions, Host, Telemetry};
use std::process::Command;
use super::Testable;
use tempdir::TempDir;

pub struct FileTest;

impl Testable for FileTest {
    fn test(mut host: &mut Host) {
        let tempdir = TempDir::new("file_test").unwrap();
        let localpath = format!("{:?}/local", tempdir.path());
        let remotepath = format!("{:?}/remote", tempdir.path());
        let mvpath = format!("{:?}/mv_file", tempdir.path());

        let telemetry = Telemetry::init(&mut host).unwrap();

        let file_dir = File::new(&mut host, "/etc");
        assert!(file_dir.is_err());

        let mut file = File::new(&mut host, &remotepath).unwrap();
        assert!(!file.exists(&mut host).unwrap());

        let create_remote = Command::new("dd").args(&["bs=1024", "if=/dev/urandom", &format!("of={}", &localpath), "count=1024"]).output().unwrap();
        assert!(create_remote.status.success());
        file.upload(&mut host, &localpath, None).unwrap();
        assert!(file.exists(&mut host).unwrap());
        let upload_check = Command::new("ls").arg(&remotepath).output().unwrap();
        assert!(upload_check.status.success());
        file.upload(&mut host, &localpath, Some(&[FileOptions::BackupExisting("_bk".into())])).unwrap();
        let upload_check = Command::new("ls").arg(&format!("{}_bk", &remotepath)).output().unwrap();
        assert!(upload_check.status.success());

        file.mv(&mut host, &mvpath).unwrap();
        let create_check = Command::new("ls").arg(&mvpath).output().unwrap();
        assert!(create_check.status.success());

        let owner = file.get_owner(&mut host).unwrap();
        assert_eq!(owner.user_name, "root");
        assert_eq!(owner.user_uid, 0);
        assert_eq!(owner.group_name, if telemetry.os.platform == "freebsd" { "wheel" } else { "root" });
        assert_eq!(owner.group_gid, 0);

        file.set_owner(&mut host, "vagrant", "vagrant").unwrap();
        let new_owner = file.get_owner(&mut host).unwrap();
        assert_eq!(new_owner.user_name, "vagrant");
        assert_eq!(new_owner.group_name, "vagrant");
        match telemetry.os.platform.as_ref() {
            "centos" => {
                assert_eq!(new_owner.user_uid, 500);
                assert_eq!(new_owner.group_gid, 500);
            },
            "ubuntu" | "debian" | "fedora" => {
                assert_eq!(new_owner.user_uid, 1000);
                assert_eq!(new_owner.group_gid, 1000);
            },
            "freebsd" => {
                assert_eq!(new_owner.user_uid, 1001);
                assert_eq!(new_owner.group_gid, 1001);
            },
            _ => unimplemented!(),
        }

        assert_eq!(file.get_mode(&mut host).unwrap(), 755);
        file.set_mode(&mut host, 777).unwrap();
        assert_eq!(file.get_mode(&mut host).unwrap(), 777);

        file.delete(&mut host).unwrap();
        let del_check = Command::new("ls").arg(&mvpath).output().unwrap();
        assert_eq!(del_check.status.code().unwrap(), if telemetry.os.platform == "freebsd" { 1 } else { 2 });
    }
}
