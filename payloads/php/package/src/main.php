<?php

use Intecture\Host;
use Intecture\Package;
use Intecture\PackageException;
use Intecture\PackageResult;
use Intecture\Providers;

assert_options(ASSERT_ACTIVE, true);
assert_options(ASSERT_BAIL, true);

if ($argc < 2) {
    echo 'Missing Host endpoints', PHP_EOL;
    exit(1);
}

$host = Host::connect_payload($argv[1], $argv[2]);

$pkg = new Package($host, "nginx");
assert(!$pkg->is_installed());

$result = $pkg->install($host);
if ($result === NULL) {
    echo 'Didn\'t install package';
    exit(1);
} else {
    assert($result['exit_code'] == 0);
}

$result = $pkg->install($host);
if ($result !== NULL) {
    echo 'Tried to install package again';
    exit(1);
}

assert($pkg->is_installed());

$result = $pkg->uninstall($host);
if ($result === NULL) {
    echo 'Didn\'t uninstall package';
    exit(1);
} else {
    assert($result['exit_code'] == 0);
}

$result = $pkg->uninstall($host);
if ($result !== NULL) {
    echo 'Tried to uninstall package again';
    exit(1);
}

assert(!$pkg->is_installed());

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
assert(!$pkg->is_installed());

try {
    $e = false;
    new Package($host, 'nginx', $bogus);
} catch (PackageException $e) {
    $e = true;
} finally {
    assert($e);
}
