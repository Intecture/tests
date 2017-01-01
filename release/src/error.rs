// Copyright 2015-2017 Intecture Developers. See the COPYRIGHT file at the
// top-level directory of this distribution and at
// https://intecture.io/COPYRIGHT.
//
// Licensed under the Mozilla Public License 2.0 <LICENSE or
// https://www.tldrlegal.com/l/mpl-2.0>. This file may not be copied,
// modified, or distributed except according to those terms.

use regex;
use ssh2;
use std::{error, fmt, io, result};
use std::convert::From;

pub type Result<T> = result::Result<T, Error>;

#[derive(Debug)]
pub enum Error {
    Authentication,
    Io(io::Error),
    Regex(regex::Error),
    Ssh2(ssh2::Error),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match *self {
            Error::Authentication => write!(f, "Failed to authenticate to host"),
            Error::Io(ref e) => write!(f, "IO error: {}", e),
            Error::Regex(ref e) => write!(f, "Regex error: {}", e),
            Error::Ssh2(ref e) => write!(f, "SSH2 error: {}", e),
        }
    }
}

impl error::Error for Error {
    fn description(&self) -> &str {
        match *self {
            Error::Authentication => "Failed to authenticate to host",
            Error::Io(ref e) => e.description(),
            Error::Regex(ref e) => e.description(),
            Error::Ssh2(ref e) => e.description(),
        }
    }

    fn cause(&self) -> Option<&error::Error> {
        match *self {
            Error::Authentication => None,
            Error::Io(ref e) => Some(e),
            Error::Regex(ref e) => Some(e),
            Error::Ssh2(ref e) => Some(e),
        }
    }
}

impl From<io::Error> for Error {
    fn from(err: io::Error) -> Error {
        Error::Io(err)
    }
}

impl From<regex::Error> for Error {
    fn from(err: regex::Error) -> Error {
        Error::Regex(err)
    }
}

impl From<ssh2::Error> for Error {
    fn from(err: ssh2::Error) -> Error {
        Error::Ssh2(err)
    }
}
