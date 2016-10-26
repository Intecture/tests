#[macro_use]
extern crate inapi;

use inapi::{Error, Host, Payload};
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

    let payload = try!(Payload::new("payload_nested::my_controller"));
    try!(payload.run(&mut host, Some(vec!["myarg"])));

    assert!(Payload::new("payload_missingdep").is_err());

    Ok(())
}
