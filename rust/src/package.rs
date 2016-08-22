use inapi::{Host, Package, PackageResult, Providers, Telemetry};
use super::Testable;

pub struct PackageTest;

impl Testable for PackageTest {
    fn test(mut host: &mut Host) {
        let telemetry = Telemetry::init(&mut host).unwrap();

        let mut pkg = Package::new(&mut host, "nginx", None).unwrap();
        assert!(!pkg.is_installed());
        if let PackageResult::Result(cmd) = pkg.install(&mut host).unwrap() {
            assert_eq!(cmd.exit_code, 0);
        } else {
            panic!("Didn't install package");
        }
        if let PackageResult::Result(_) = pkg.install(&mut host).unwrap() {
            panic!("Tried to install package again");
        }
        assert!(pkg.is_installed());
        if let PackageResult::Result(cmd) = pkg.uninstall(&mut host).unwrap() {
            assert_eq!(cmd.exit_code, 0);
        } else {
            panic!("Didn't uninstall package");
        }
        if let PackageResult::Result(_) = pkg.uninstall(&mut host).unwrap() {
            panic!("Tried to uninstall package again");
        }
        assert!(!pkg.is_installed());

        let (ok, bogus) = match telemetry.os.platform.as_ref() {
            "centos" => (Providers::Yum, Providers::Pkg),
            "debian" | "ubuntu" => (Providers::Apt, Providers::Homebrew),
            "fedora" => (Providers::Dnf, Providers::Apt),
            "freebsd" => (Providers::Pkg, Providers::Yum),
            "macos" => (Providers::Homebrew, Providers::Dnf),
            _ => unimplemented!(),
        };
        let pkg = Package::new(&mut host, "nginx", Some(ok)).unwrap();
        assert!(!pkg.is_installed());

        assert!(Package::new(&mut host, "nginx", Some(bogus)).is_err());
    }
}
