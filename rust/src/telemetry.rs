use inapi::{Host, Telemetry};
use std::process::Command;
use super::Testable;

pub struct TelemetryTest;

impl Testable for TelemetryTest {
    fn test(mut host: &mut Host) {
        let telemetry = Telemetry::init(&mut host).unwrap();
        let output = Command::new("hostname").output().unwrap();
        assert!(output.status.success());
        assert_eq!(String::from_utf8(output.stdout).unwrap(), telemetry.hostname);
    }
}
