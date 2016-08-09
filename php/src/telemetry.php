<?php

use Intecture\Telemetry;

class TelemetryTest implements Testable {
    public static function test($host) {
        $telemetry = Telemetry::load($host);
        $tdata = $telemetry->get();
        $out = $exit = NULL;
        $check_start = exec('hostname -f', $out, $exit);
        assert($exit == 0);
        assert($tdata['hostname'] == $out[0]);
    }
}
