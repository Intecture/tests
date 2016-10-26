#[macro_use]
extern crate inapi;
extern crate tempdir;

use inapi::{Error, File, FileOptions, Host};
use std::env;
use std::process::{Command, exit};
use tempdir::TempDir;

fn main() {
    let args: Vec<_> = env::args().collect();
    if args.len() < 3 {
        println!("Missing Host endpoints");
        exit(1);
    }

    if let Err(e) = run(&args[1], &args[2]) {
        println!(""); // Output line break
        println!("{}", e);
        exit(1);
    }
}

fn run(api_endpoint: &str, file_endpoint: &str) -> Result<(), Error> {
    let mut host = try!(Host::connect_payload(api_endpoint, file_endpoint));
    let data = host.data_owned();

    let tempdir = TempDir::new("file_test").unwrap();
    let localpath = format!("{}/local", tempdir.path().to_str().unwrap());
    let remotepath = format!("{}/remote", tempdir.path().to_str().unwrap());
    let mvpath = format!("{}/mv_file", tempdir.path().to_str().unwrap());
    let copypath = format!("{}/cp_file", tempdir.path().to_str().unwrap());

    let platform = try!(needstr!(data => "/_telemetry/os/platform"));

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
    let mv_check = Command::new("ls").arg(&mvpath).output().unwrap();
    assert!(mv_check.status.success());
    let mv_check = Command::new("ls").arg(&remotepath).output().unwrap();
    assert!(!mv_check.status.success());

    file.copy(&mut host, &copypath).unwrap();
    let copy_check = Command::new("ls").arg(&mvpath).output().unwrap();
    assert!(copy_check.status.success());
    let copy_check = Command::new("ls").arg(&copypath).output().unwrap();
    assert!(copy_check.status.success());

    let owner = file.get_owner(&mut host).unwrap();
    assert_eq!(owner.user_name, "root");
    assert_eq!(owner.user_uid, 0);
    assert_eq!(owner.group_name, if platform == "freebsd" { "wheel" } else { "root" });
    assert_eq!(owner.group_gid, 0);

    file.set_owner(&mut host, "vagrant", "vagrant").unwrap();
    let new_owner = file.get_owner(&mut host).unwrap();
    assert_eq!(new_owner.user_name, "vagrant");
    assert_eq!(new_owner.group_name, "vagrant");
    assert_eq!(new_owner.user_uid, try!(needu64!(data => "/file/file_owner")));
    assert_eq!(new_owner.group_gid, try!(needu64!(data => "/file/file_owner")));

    assert_eq!(file.get_mode(&mut host).unwrap(), 644);
    file.set_mode(&mut host, 777).unwrap();
    assert_eq!(file.get_mode(&mut host).unwrap(), 777);

    file.delete(&mut host).unwrap();
    let del_check = Command::new("ls").arg(&mvpath).output().unwrap();
    assert_eq!(del_check.status.code().unwrap(), if platform == "freebsd" { 1 } else { 2 });

    Ok(())
}
