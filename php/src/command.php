<?php

use Intecture\Command;

class CommandTest implements Testable {
    public static function test($host) {
        $whoami = new Command('whoami');
        $result = $whoami->exec($host);
        assert($result['exit_code'] == 0);
        assert($result['stdout'] == 'root');
        assert($result['stderr'] == '');
    }
}
