extern crate inapi;
extern crate tempdir;

mod command;
mod directory;
mod file;
mod package;
mod service;
mod telemetry;

use inapi::Host;

trait Testable {
    fn test(host: &mut Host);
}

fn main() {
    let mut host = Host::new();
    host.connect("localhost", 7101, 7102, "localhost:7103").unwrap();

    print!("Testing command...");
    command::CommandTest::test(&mut host);
    println!("done");

    print!("Testing directory...");
    directory::DirectoryTest::test(&mut host);
    println!("done");

    print!("Testing file...");
    file::FileTest::test(&mut host);
    println!("done");

    print!("Testing package...");
    package::PackageTest::test(&mut host);
    println!("done");

    print!("Testing service...");
    service::ServiceTest::test(&mut host);
    println!("done");

    print!("Testing telemetry...");
    telemetry::TelemetryTest::test(&mut host);
    println!("done");

    println!("ALL TESTS PASSED. DO THE BART MAN!");
    println!("
                  _,----.
               ,-'     __`.
              /    .  /--\\`)
             /  .  )\\/_,--\\
            /  ,'\\/,-'    _\\_
           |  /  ,' ,---'  __\\
          ,' / ,:     _,-\'_,(
           (/ /  \\ \\,'   |'  _)         ,. ,.,.
            \\/   |          '  \\        \\ ,. \\ )
             \\, ,-              \\       /,' )//
              ; \'`      _____,-'      _|`  ,'
               \\ `\"\\    (_,'_)     _,-'    ,'
                \\   \\       \\  _,-'       ,'
                |, , )       `'       _,-'
                /`/ Y    ,    \\   _,-'
                   :    /      \\-'
                   |     `--.__\\___
                   |._           __)
         -hrr-     |  `--.___    _)
                   |         `----'
                  /                \\
                 '                . ) ");
}
