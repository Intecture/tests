use inapi::{Host, Package, PackageResult, Service, ServiceRunnable, Telemetry};
use std::process::Command;
use super::Testable;

pub struct ServiceTest;

impl Testable for ServiceTest {
    fn test(mut host: &mut Host) {
        let telemetry = Telemetry::init(&mut host).unwrap();

        if telemetry.os.platform == "centos" {
            let mut pkg_epel = Package::new(&mut host, "epel-release", None).unwrap();
            if let PackageResult::Result(cmd) = pkg_epel.install(&mut host).unwrap() {
                assert_eq!(cmd.exit_code, 0);
            }
        }

        let mut pkg = Package::new(&mut host, "nginx", None).unwrap();
        if let PackageResult::Result(cmd) = pkg.install(&mut host).unwrap() {
            assert_eq!(cmd.exit_code, 0);
        }

        let service = Service::new_service(ServiceRunnable::Service("nginx"), None);

        let enable = service.action(&mut host, "enable").unwrap();
        assert_eq!(enable.exit_code, 0);
        match telemetry.os.platform.as_ref() {
            "centos" => {
                let cmd = Command::new("bash").args(&["-c", "chkconfig|egrep -qs 'nginx.+3:on'"]).output().unwrap();
                assert!(cmd.status.success());
            },
            "fedora" => {
                let cmd = Command::new("bash").args(&["-c", "systemctl list-unit-files|egrep -qs 'nginx.service.+enabled'"]).output().unwrap();
                assert!(cmd.status.success());
            },
            "debian" | "ubuntu" => {
                let cmd = Command::new("bash").args(&["-c", "ls /etc/rc3.d|egrep -qs 'S[0-9]+nginx'"]).output().unwrap();
                assert!(cmd.status.success());
            },
            "freebsd" => {
                let cmd = Command::new("grep").args(&["-qs", "nginx_enable=\"YES\"", "/etc/rc.conf"]).output().unwrap();
                assert!(cmd.status.success());
            }
            _ => unimplemented!()
        }

        let start = service.action(&mut host, "start").unwrap();
        assert_eq!(start.exit_code, 0);
        let start_cmd = Command::new("pgrep").arg("nginx").output().unwrap();
        assert!(start_cmd.status.success());

        let stop = service.action(&mut host, "stop").unwrap();
        assert_eq!(stop.exit_code, 0);
        let stop_cmd = Command::new("pgrep").arg("nginx").output().unwrap();
        assert_eq!(stop_cmd.status.code().unwrap(), 1);

        let disable = service.action(&mut host, "disable").unwrap();
        assert_eq!(disable.exit_code, 0);
        match telemetry.os.platform.as_ref() {
            "centos" => {
                let cmd = Command::new("bash").args(&vec!["-c", "chkconfig|egrep -qs 'nginx.+3:off'"]).output().unwrap();
                assert!(cmd.status.success());
            },
            "fedora" => {
                let cmd = Command::new("bash").args(&vec!["-c", "systemctl list-unit-files|egrep -qs 'nginx.service.+disabled'"]).output().unwrap();
                assert!(cmd.status.success());
            },
            "debian" | "ubuntu" => {
                let cmd = Command::new("bash").args(&vec!["-c", "ls /etc/rc3.d|egrep -qs 'S[0-9]+nginx'"]).output().unwrap();
                assert!(cmd.status.success() == false);
            },
            "freebsd" => {
                let cmd = Command::new("grep").args(&vec!["-qs", "nginx_enable", "/etc/rc.conf"]).output().unwrap();
                assert!(cmd.status.success() == false);
            }
            _ => unimplemented!()
        }

        let mut pkg = Package::new(&mut host, "nginx", None).unwrap();
        if let PackageResult::Result(cmd) = pkg.uninstall(&mut host).unwrap() {
            assert_eq!(cmd.exit_code, 0);
        }
    }
}
