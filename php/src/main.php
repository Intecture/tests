<?php

use Intecture\Host;

interface Testable {
    function test($host);
}

assert_options(ASSERT_ACTIVE, true);
assert_options(ASSERT_BAIL, true);

require('command.php');
require('directory.php');
require('file.php');
require('package.php');
require('service.php');
require('telemetry.php');

$host = new Host();
$host->connect("localhost", 7101, 7102, "localhost:7103");

echo "Testing command...";
CommandTest::test($host);
echo "done", PHP_EOL;

echo "Testing directory...";
DirectoryTest::test($host);
echo "done", PHP_EOL;

echo "Testing file...";
FileTest::test($host);
echo "done", PHP_EOL;

echo "Testing package...";
PackageTest::test($host);
echo "done", PHP_EOL;

echo "Testing service...";
ServiceTest::test($host);
echo "done", PHP_EOL;

echo "Testing telemetry...";
TelemetryTest::test($host);
echo "done", PHP_EOL;

echo "ALL TESTS PASSED. RRAAAAAWWWW!", PHP_EOL;
echo "                      __
                          ,' ,^,.
                      ,-\"/\"\"/--)_\
                    ,'           /.
                   ,'              \
                   |               ;
                  /                |
                 ,'    ,'    .     ;
                (_____|_______\   :
                (o___,|o      | /|,
                 (    `.____,' / /.\
                 /`-----._       e )
                |         `.    |-'
                |      __,-.`.  |
                `--.-'\ \_\' :  |
                    \_,^'   ,'  \
                    '.____,'  _,'\
                   (`-|_,-'\")'  ,'\--._
                    )=(_)=  \--'       `-._
                   /`-' `---'              `.
                  / /                        `-.
                 / /                            `-.
                : /                               `.
                |( .        .       ---._          `.
                |'                  ''' \`-.        |
               /                         `. \       |
              /                            \ :      |
             /                              \)      |
            /                             __/       ;
           :                             (___      :
           |                              ,` `.     ) ))
           |       o                  _,-' ,'_/  ;;/ //
           |`--.____           ___,--' _,-' (__,'-'
           |`--.____`---------'____,--'       ; - -'
           `.  ,' / `---,-.---'              /
             \/  /      \  \         ____  ,'
              `./        `. `.  _,--'    )/
               |`-.        `.,`'         /
               |   `-._    /            :
               :       `--|             |
               |          |             |
               |          |             |
               |          |             |
               |          |             |
               |          |             :
               |          |             |
               |          |             |
               |, --.     |             |
             ,-'           :_, --.      :
          _,'            _,'             \
         (,',,--    __,-/                 )
          `((___,--' ,-'             _,--'
                    (_( ,',-  __,---'
                       ``-`--'";
