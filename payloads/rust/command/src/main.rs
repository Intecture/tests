#[macro_use]
extern crate inapi;

use inapi::{Command, Error, Host};
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

    let whoami = Command::new(try!(needstr!(host.data() => "/command/cmd")));
    let result = whoami.exec(&mut host).unwrap();
    assert_eq!(result.exit_code, 0);
    assert_eq!(result.stdout, "root");
    assert_eq!(result.stderr, "");

    Ok(())
}
