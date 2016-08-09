<?php

use Intecture\Command;

class CommandTest implements Testable {
    private $host;

    public function test($host) {
        $whoami = new Command('whoami');
        $result = $whoami->exec($host);
        assert($result['exit_code'] == 0);
        assert($result['stdout'] == 'root');
        assert($result['stderr'] == '');
    }
}
