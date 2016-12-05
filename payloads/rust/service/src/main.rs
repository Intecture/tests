#[macro_use]
extern crate inapi;

use inapi::{Error, Host, Package, Service, ServiceRunnable};
use std::env;
use std::process::{Command, exit};

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

    let platform = try!(needstr!(data => "/_telemetry/os/platform"));
    let version = try!(needu64!(data => "/_telemetry/os/version_maj"));

    if platform == "centos" {
        let mut pkg_epel = Package::new(&mut host, "epel-release", None).unwrap();
        if let Some(cmd) = pkg_epel.install(&mut host).unwrap() {
            assert_eq!(cmd.exit_code, 0);
        }
    }

    let mut pkg = Package::new(&mut host, "nginx", None).unwrap();
    if let Some(cmd) = pkg.install(&mut host).unwrap() {
        assert_eq!(cmd.exit_code, 0);
    }

    let service = Service::new_service(ServiceRunnable::Service("nginx"), None);

    if let Some(enable) = service.action(&mut host, "enable").unwrap() {
        assert_eq!(enable.exit_code, 0);
    }
    match platform {
        "centos" if version <= 6 => {
            let cmd = try!(Command::new("bash").args(&["-c", "chkconfig|egrep -qs 'nginx.+3:on'"]).output());
            assert!(cmd.status.success());
        },
        "fedora" | "centos" => {
            let cmd = try!(Command::new("bash").args(&["-c", "systemctl list-unit-files|egrep -qs 'nginx.service.+enabled'"]).output());
            assert!(cmd.status.success());
        },
        "debian" | "ubuntu" => {
            let cmd = try!(Command::new("bash").args(&["-c", "ls /etc/rc3.d|egrep -qs 'S[0-9]+nginx'"]).output());
            assert!(cmd.status.success());
        },
        "freebsd" => {
            let cmd = try!(Command::new("grep").args(&["-qs", "nginx_enable=\"YES\"", "/etc/rc.conf"]).output());
            assert!(cmd.status.success());
        }
        _ => unimplemented!()
    }

    let enable = try!(service.action(&mut host, "enable"));
    assert!(enable.is_none());

    if let Some(start) = try!(service.action(&mut host, "start")) {
        assert_eq!(start.exit_code, 0);
    }
    let start_cmd = try!(Command::new("pgrep").arg("nginx").output());
    assert!(start_cmd.status.success());

    let start = try!(service.action(&mut host, "start"));
    assert!(start.is_none());

    let stop = try!(service.action(&mut host, "stop")).unwrap();
    assert_eq!(stop.exit_code, 0);
    let stop_cmd = try!(Command::new("pgrep").arg("nginx").output());
    assert_eq!(stop_cmd.status.code().unwrap(), 1);

    let stop = try!(service.action(&mut host, "stop"));
    assert!(stop.is_none());

    let disable = try!(service.action(&mut host, "disable")).unwrap();
    assert_eq!(disable.exit_code, 0);
    match platform {
        "centos" if version <= 6 => {
            let cmd = try!(Command::new("bash").args(&vec!["-c", "chkconfig|egrep -qs 'nginx.+3:off'"]).output());
            assert!(cmd.status.success());
        },
        "fedora" | "centos" => {
            let cmd = try!(Command::new("bash").args(&vec!["-c", "systemctl list-unit-files|egrep -qs 'nginx.service.+disabled'"]).output());
            assert!(cmd.status.success());
        },
        "debian" | "ubuntu" => {
            let cmd = try!(Command::new("bash").args(&vec!["-c", "ls /etc/rc3.d|egrep -qs 'S[0-9]+nginx'"]).output());
            assert!(cmd.status.success() == false);
        },
        "freebsd" => {
            let cmd = try!(Command::new("grep").args(&vec!["-qs", "nginx_enable", "/etc/rc.conf"]).output());
            assert!(cmd.status.success() == false);
        }
        _ => unimplemented!()
    }

    let disable = try!(service.action(&mut host, "disable"));
    assert!(disable.is_none());

    let mut pkg = try!(Package::new(&mut host, "nginx", None));
    if let Some(cmd) = try!(pkg.uninstall(&mut host)) {
        assert_eq!(cmd.exit_code, 0);
    }

    Ok(())
}
