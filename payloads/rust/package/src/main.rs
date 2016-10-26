#[macro_use]
extern crate inapi;

use inapi::{Error, Host, Package, Providers};
use std::env;
use std::process::exit;

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

    let mut pkg = try!(Package::new(&mut host, "nginx", None));

    assert!(!pkg.is_installed());
    if let Some(cmd) = try!(pkg.install(&mut host)) {
        assert_eq!(cmd.exit_code, 0);
    } else {
        panic!("Didn't install package");
    }

    if try!(pkg.install(&mut host)).is_some() {
        panic!("Tried to install package again");
    }
    assert!(pkg.is_installed());

    if let Some(cmd) = try!(pkg.uninstall(&mut host)) {
        assert_eq!(cmd.exit_code, 0);
    } else {
        panic!("Didn't uninstall package");
    }
    if try!(pkg.uninstall(&mut host)).is_some() {
        panic!("Tried to uninstall package again");
    }
    assert!(!pkg.is_installed());

    let (ok, bogus) = match try!(needstr!(data => "/_telemetry/os/platform")) {
        "centos" => (Providers::Yum, Providers::Pkg),
        "debian" | "ubuntu" => (Providers::Apt, Providers::Homebrew),
        "fedora" => (Providers::Dnf, Providers::Apt),
        "freebsd" => (Providers::Pkg, Providers::Yum),
        "macos" => (Providers::Homebrew, Providers::Dnf),
        _ => unimplemented!(),
    };
    let pkg = try!(Package::new(&mut host, "nginx", Some(ok)));
    assert!(!pkg.is_installed());

    assert!(Package::new(&mut host, "nginx", Some(bogus)).is_err());

    Ok(())
}
