<?php

use Intecture\Command;
use Intecture\Host;
use Intecture\Package;
use Intecture\PackageException;
use Intecture\PackageResult;
use Intecture\Providers;

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

if ($host->data()['_telemetry']['os']['platform'] == "centos") {
    $epel_cmd = new Command('yum install -y epel-release');
    $result = $epel_cmd->exec($host);

    actually_bloody_assert($result['exit_code'], 0);
}

$pkg = new Package($host, "nginx");
actually_bloody_assert($pkg->is_installed(), false);

$result = $pkg->install($host);
if ($result === NULL) {
    echo 'Didn\'t install package';
    exit(1);
} else {
    actually_bloody_assert($result['exit_code'], 0);
}

$result = $pkg->install($host);
if ($result !== NULL) {
    echo 'Tried to install package again';
    exit(1);
}

actually_bloody_assert($pkg->is_installed(), true);

$result = $pkg->uninstall($host);
if ($result === NULL) {
    echo 'Didn\'t uninstall package';
    exit(1);
} else {
    actually_bloody_assert($result['exit_code'], 0);
}

$result = $pkg->uninstall($host);
if ($result !== NULL) {
    echo 'Tried to uninstall package again';
    exit(1);
}

actually_bloody_assert($pkg->is_installed(), false);

$ok = $bogus = NULL;
switch ($host->data()['_telemetry']['os']['platform']) {
    case "centos":
        $ok = Package::PROVIDER_YUM;
        $bogus = Package::PROVIDER_PKG;
        break;
    case "debian":
    case "ubuntu":
        $ok = Package::PROVIDER_APT;
        $bogus = Package::PROVIDER_HOMEBREW;
        break;
    case "fedora":
        $ok = Package::PROVIDER_DNF;
        $bogus = Package::PROVIDER_APT;
        break;
    case "freebsd":
        $ok = Package::PROVIDER_PKG;
        $bogus = Package::PROVIDER_YUM;
        break;
    case "macos":
        $ok = Package::PROVIDER_HOMEBREW;
        $break = Package::PROVIDER_DNF;
        break;
};

$pkg = new Package($host, 'nginx', $ok);
actually_bloody_assert($pkg->is_installed(), false);

try {
    $e = false;
    new Package($host, 'nginx', $bogus);
} catch (PackageException $e) {
    $e = true;
} finally {
    actually_bloody_assert($e, true);
}

function actually_bloody_assert($v1, $v2, $ne = false) {
    if (!$ne && $v1 !== $v2) {
        echo "Failed assertion: $v1 === $v2", PHP_EOL;
        exit(1);
    }
    else if ($ne && $v1 === $v2) {
        echo "Failed assertion: $v1 !== $v2", PHP_EOL;
        exit(1);
    }
}
