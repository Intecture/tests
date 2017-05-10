#[macro_use]
extern crate inapi;

use inapi::{Error, Host};
use std::{env, str};
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
    let host = try!(Host::connect_payload(api_endpoint, file_endpoint));
    let data = host.data_owned();

    // Local data
    assert!(wantnull!(data => "/data/null").is_some());
    assert_eq!(wantbool!(data => "/data/bool"), Some(true));
    assert_eq!(wanti64!(data => "/data/int"), Some(-123));
    assert_eq!(wantu64!(data => "/data/uint"), Some(123));
    assert_eq!(wantf64!(data => "/data/double"), Some(1.1));
    assert_eq!(wantstr!(data => "/data/str"), Some("This is a string"));
    let mut a = try!(needarray!(data => "/data/array")).iter();
    let next = a.next().unwrap();
    assert_eq!(wantu64!(next), Some(1));
    let next = a.next().unwrap();
    assert_eq!(wantstr!(next), Some("two"));
    let next = a.next().unwrap();
    assert_eq!(wantu64!(next), Some(3));
    assert_eq!(wantstr!(data => "/data/obj/nested"), Some("Boo!"));

    // Telemetry data
    let output = try!(Command::new("hostname").output());
    assert!(output.status.success());
    assert_eq!(wantstr!(data => "/_telemetry/hostname"), Some(try!(str::from_utf8(&output.stdout)).trim()));

    Ok(())
}
