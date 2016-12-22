// Copyright 2015-2016 Intecture Developers. See the COPYRIGHT file at the
// top-level directory of this distribution and at
// https://intecture.io/COPYRIGHT.
//
// Licensed under the Mozilla Public License 2.0 <LICENSE or
// https://www.tldrlegal.com/l/mpl-2.0>. This file may not be copied,
// modified, or distributed except according to those terms.

extern crate docopt;
extern crate regex;
extern crate rustc_serialize;
extern crate ssh2;
extern crate toml;

mod error;

use docopt::Docopt;
use error::{Error, Result};
use regex::Regex;
use ssh2::Session;
use std::{fmt, fs};
use std::io::prelude::*;
use std::net::TcpStream;
use std::path::Path;
use std::process::exit;

const RELEASECONF: &'static str = "release.toml";
const STATICDIR: &'static str = "/usr/local/www/static.intecture.io";

static USAGE: &'static str = "
Package release manager

Usage:
  release upload [-p <project>] [-t <target>]
  release (-h | --help)

Options:
  -h --help     Show this screen.
  -p <project>  Specify a project to use.
  -t <target>   Specify a target (e.g. freebsd).
";

#[derive(Debug, RustcDecodable)]
struct Args {
    cmd_upload: bool,
    flag_h: bool,
    flag_help: bool,
    flag_p: Option<Project>,
    flag_t: Option<Target>,
}

#[derive(Debug, RustcDecodable)]
struct Config {
    hostname: String,
    port: Option<u32>,
    username: String,
    password: Option<String>,
    private_key: Option<String>,
}

#[derive(Clone, Copy, Debug, PartialEq, RustcDecodable)]
enum Project {
    Agent,
    Api,
    Auth,
    Cli,
}

impl fmt::Display for Project {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match *self {
            Project::Agent => write!(f, "agent"),
            Project::Api => write!(f, "api"),
            Project::Auth => write!(f, "auth"),
            Project::Cli => write!(f, "cli"),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, RustcDecodable)]
enum Target {
    Centos,
    Darwin,
    Debian,
    Fedora,
    Freebsd,
    Ubuntu,
}

impl fmt::Display for Target {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match *self {
            Target::Centos => write!(f, "centos"),
            Target::Darwin => write!(f, "darwin"),
            Target::Debian => write!(f, "debian"),
            Target::Fedora => write!(f, "fedora"),
            Target::Freebsd => write!(f, "freebsd"),
            Target::Ubuntu => write!(f, "ubuntu"),
        }
    }
}

fn main() {
    let args: Args = Docopt::new(USAGE)
        .and_then(|d| d.decode())
        .unwrap_or_else(|e| e.exit());

    if let Err(e) = run(&args) {
        println!("{}", e);
        println!("{:?}", e);
        exit(1);
    }
}

fn run(args: &Args) -> Result<()> {
    let mut fh = fs::File::open(RELEASECONF)?;
    let mut conf_str = String::new();
    fh.read_to_string(&mut conf_str)?;

    let conf: Config = toml::decode_str(&conf_str).unwrap();
    let (_tcp, sess) = connect(&conf)?;

    if args.cmd_upload {
        upload(args, &sess)?;
    }

    Ok(())
}

fn connect(conf: &Config) -> Result<(TcpStream, Session)> {
    let tcp = TcpStream::connect(&*format!("{}:{}", &conf.hostname, conf.port.unwrap_or(22)))?;
    let mut sess = Session::new().unwrap();
    sess.handshake(&tcp)?;

    if let Some(ref i) = conf.private_key {
        sess.userauth_pubkey_file(&conf.username, None, Path::new(i), None)?;
    }
    else if let Some(ref p) = conf.password {
        sess.userauth_password(&conf.username, p).unwrap();
    } else {
        sess.userauth_agent(&conf.username)?;
    }

    if sess.authenticated() {
        Ok((tcp, sess))
    } else {
        Err(Error::Authentication)
    }
}

fn upload(args: &Args, sess: &Session) -> Result<()> {
    let re = Regex::new(r"^[a-z]+-([0-9]+\.[0-9]+\.[0-9]+)\.tar\.bz2")?;

    if let Some(proj) = args.flag_p {
        upload_project(sess, &re, proj, args.flag_t)?;
    } else {
        for proj in [Project::Agent, Project::Api, Project::Auth, Project::Cli].iter() {
            upload_project(sess, &re, *proj, args.flag_t)?;
        }
    }
    Ok(())
}

fn upload_project(sess: &Session, re: &Regex, project: Project, target: Option<Target>) -> Result<()> {
    let mut fh = fs::File::open(&format!("{}/Cargo.toml", project))?;
    let mut cargo_str = String::new();
    fh.read_to_string(&mut cargo_str)?;

    let mut parser = toml::Parser::new(&cargo_str);
    let cargo = toml::Value::Table(parser.parse().unwrap());
    let version = cargo.lookup("package.version").expect("Missing Cargo version").as_str().unwrap();

    if let Some(tgt) = target {
        upload_project_target(sess, re, project, tgt, version)?;
    } else {
        for tgt in [Target::Centos, Target::Darwin, Target::Debian, Target::Fedora, Target::Freebsd, Target::Ubuntu].iter() {
            upload_project_target(sess, re, project, *tgt, version)?;
        }
    }
    Ok(())
}

fn upload_project_target(sess: &Session, re: &Regex, project: Project, target: Target, version: &str) -> Result<()> {
    let filename = format!("in{}-{}.tar.bz2", project, version);
    let local_path = format!("{}/.pkg/{}/{}", project, target, filename);
    let remote_path = format!("{}/{}/{}", STATICDIR, project, target);

    let mut local_file = match fs::File::open(&local_path) {
        Ok(f) => {
            println!("Uploading {} [{}]", project, target);
            f
        },
        Err(_) => {
            println!("Skipping {} [{}]. File not found in {}.", project, target, local_path);
            return Ok(());
        }
    };

    // Ensure remote path exists
    let mut channel = sess.channel_session()?;
    channel.exec(&format!("/bin/mkdir -p {}", remote_path))?;

    // Create remote file
    let mut remote_file = sess.scp_send(Path::new(&format!("{}/{}", remote_path, filename)), 0o644, local_file.metadata()?.len(), None).unwrap();

    // Upload contents
    let mut buf = [0u8; 1024];
    while local_file.read(&mut buf)? > 0 {
        remote_file.write_all(&buf)?;
    }

    // Publish, if this is latest version available
    let mut channel = sess.channel_session()?;
    channel.exec(&format!("ls {} | grep .tar.bz2 | sort -nr | head -1", remote_path))?;
    let mut latest_file = String::new();
    channel.read_to_string(&mut latest_file)?;
    let cap = re.captures(&latest_file).unwrap();
    let latest = cap.at(1).unwrap();

    if compare_semver(version, latest) >= 0 {
        println!("Publishing...");
        let mut channel = sess.channel_session()?;
        channel.exec(&format!("ln -sf {}/{} {0}/latest", remote_path, filename))?;
    }

    Ok(())
}

fn compare_semver(greater_than: &str, less_than: &str) -> i8 {
    let gt: Vec<u32> = greater_than.split('.').map(|s| s.parse::<u32>().unwrap()).collect();
    assert_eq!(gt.len(), 3);
    let lt: Vec<u32> = less_than.split('.').map(|s| s.parse::<u32>().unwrap()).collect();
    assert_eq!(lt.len(), 3);

    for i in 0..2 {
        if gt[i] > lt[i] {
            return 1;
        }
        else if gt[i] < lt[i] {
            return -1;
        }
    }

    0
}

#[cfg(test)]
mod tests {
    use super::compare_semver;

    #[test]
    fn test_compare_semver() {
        assert_eq!(compare_semver("3.2.1", "1.2.3"), 1);
        assert_eq!(compare_semver("1.2.3", "1.2.3"), 0);
        assert_eq!(compare_semver("1.2.3", "3.2.1"), -1);
    }
}
