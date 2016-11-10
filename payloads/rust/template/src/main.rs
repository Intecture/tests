#[macro_use]
extern crate inapi;
extern crate tempdir;

use inapi::{Error, File, Host, MapBuilder, Template};
use std::{env, fs};
use std::io::Read;
use std::process::exit;
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

    let tempdir = try!(TempDir::new("test_template"));

    let tpl = try!(Template::new("template/tpl/test_conf.tpl"));
    let map = MapBuilder::new()
        .insert_str("name", try!(needstr!(host.data_owned() => "/template/name")))
        .build();
    let fs_file = try!(tpl.render_data(&map));

    let filename = format!("{}/test_conf.conf", tempdir.path().to_str().unwrap());
    let expected_content = "Hello world!";

    let file = try!(File::new(&mut host, &filename));
    try!(file.upload_file(&mut host, fs_file, None));

    let mut fh = try!(fs::File::open(filename));
    let mut content = String::new();
    try!(fh.read_to_string(&mut content));

    assert_eq!(content.trim(), expected_content);

    Ok(())
}
