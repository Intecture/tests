#include <assert.h>
#include "header.h"
#include <inapi.h>
#include <stdio.h>
#include <string.h>

int main (int argc, char *argv[]) {
    Host host = host_new();
    host_connect(&host, "localhost", 7101, 7102, "localhost:7103");

    printf("Testing command...");
    assert(command_test(&host));
    printf("done\n");

    // printf("Testing directory...");
    // assert(directory_test(&host));
    // printf("done\n");

    // print("Testing file...");
    // assert(file_test(&host));
    // print("done\n");
    //
    // print("Testing package...");
    // assert(package_test(&host));
    // print("done\n");
    //
    // print("Testing service...");
    // assert(service_test(&host));
    // print("done\n");
    //
    // print("Testing telemetry...");
    // assert(telemetry_test(&host));
    // print("done\n");

    printf("ALL TESTS PASSED. HI-DIDDLY-HO NEIGHBOUR-EENO!\n\n");
    printf("    .sS$$$$$$$$$$$$$$Ss."
"   .$$$$$$$$$$$$$$$$$$$$$$s."
"   $$$$$$$$$$$$$$$$$$$$$$$$S."
"   $$$$$$$$$$$$$$$$$$$$$$$$$$s."
"   S$$$$'        `$$$$$$$$$$$$$"
"   `$$'            `$$$$$$$$$$$."
"    :               `$$$$$$$$$$$"
"   :                 `$$$$$$$$$$"
".====.  ,=====.       $$$$$$$$$$"
".'      ~'       \".    s$$$$$$$$$$"
":       :         :=_  $$$$$$$$$$$"
"`.  ()  :   ()    ' ~=$$$$$$$$$$$'"
"~====~`.      .'    $$$$$$$$$$$"
" .'     ~====~     sS$$$$$$$$$'"
" :      .         $$$$$' $$$$"
".sS$$$$$$$$Ss.     `$$'   $$$'"
"$$$$$$$$$$$$$$$s         s$$$$"
"$SSSSSSSSSSSSSSS$        $$$$$"
"   :                   $$$$'"
"    `.                 $$$'"
"      `.               :"
"       :               :"
"       :              .'`."
"      .'.           .'   :"
"     : .$s.       .'    .'"
"     :.S$$$S.   .'    .'"
"     : $$$$$$`.'    .'"
"        $$$$   `. .'"
"                 `");

    return 0;
}
