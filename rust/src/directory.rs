use inapi::{Directory, DirectoryOpts, Host, Telemetry};
use std::process::Command;
use super::Testable;
use tempdir::TempDir;

pub struct DirectoryTest;

impl Testable for DirectoryTest {
    fn test(mut host: &mut Host) {
        let tempdir = TempDir::new("directory_test").unwrap();
        let testpath = format!("{}/path/to/dir", tempdir.path().to_str().unwrap());
        let mvpath = format!("{}/path/to/mv_dir", tempdir.path().to_str().unwrap());

        let telemetry = Telemetry::init(&mut host).unwrap();

        let file_dir = Directory::new(&mut host, "/etc/hosts");
        assert!(file_dir.is_err());

        let mut dir = Directory::new(&mut host, &testpath).unwrap();
        assert!(!dir.exists(&mut host).unwrap());

        assert!(dir.create(&mut host, None).is_err());
        dir.create(&mut host, Some(&vec![DirectoryOpts::DoRecursive])).unwrap();
        assert!(dir.exists(&mut host).unwrap());
        let create_check = Command::new("ls").arg(&testpath).output().unwrap();
        assert!(create_check.status.success());

        dir.mv(&mut host, &mvpath).unwrap();
        let create_check = Command::new("ls").arg(&mvpath).output().unwrap();
        assert!(create_check.status.success());

        let owner = dir.get_owner(&mut host).unwrap();
        assert_eq!(owner.user_name, "root");
        assert_eq!(owner.user_uid, 0);
        assert_eq!(owner.group_name, if telemetry.os.platform == "freebsd" { "wheel" } else { "root" });
        assert_eq!(owner.group_gid, 0);

        dir.set_owner(&mut host, "vagrant", "vagrant").unwrap();
        let new_owner = dir.get_owner(&mut host).unwrap();
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

        assert_eq!(dir.get_mode(&mut host).unwrap(), 755);
        dir.set_mode(&mut host, 777).unwrap();
        assert_eq!(dir.get_mode(&mut host).unwrap(), 777);

        let touch_check = Command::new("touch").arg(&format!("{}/test", &mvpath)).output().unwrap();
        assert!(touch_check.status.success());
        assert!(dir.delete(&mut host, None).is_err());
        dir.delete(&mut host, Some(&vec![DirectoryOpts::DoRecursive])).unwrap();
        let del_check = Command::new("ls").arg(&mvpath).output().unwrap();
        assert_eq!(del_check.status.code().unwrap(), if telemetry.os.platform == "freebsd" { 1 } else { 2 });
    }
}
