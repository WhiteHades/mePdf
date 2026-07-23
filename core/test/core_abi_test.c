#include "mepdf/core.h"

#include <stdio.h>

int main(void)
{
    uint32_t version = mepdf_abi_version();

    if (version != MEPDF_ABI_VERSION) {
        fprintf(stderr, "expected ABI %u, got %u\n", MEPDF_ABI_VERSION, version);
        return 1;
    }

    return 0;
}
