#include <assert.h>
#include "header.h"
#include <inapi.h>
#include <string.h>

int command_test (Host *host) {
    Command whoami = command_new("whoami");
    CommandResult result = command_exec(&whoami, host);
    assert(result.exit_code == 0);
    assert(strcmp(result.stdout, "root") == 0);
    assert(strcmp(result.stderr, "") == 0);

    return 0;
}
