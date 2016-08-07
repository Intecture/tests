use inapi::{Command, Host};
use super::Testable;

pub struct CommandTest;

impl Testable for CommandTest {
    fn test(mut host: &mut Host) {
        let whoami = Command::new("whoami");
        let result = whoami.exec(&mut host).unwrap();
        assert_eq!(result.exit_code, 0);
        assert_eq!("root", result.stdout);
        assert_eq!("", result.stderr);
    }
}
