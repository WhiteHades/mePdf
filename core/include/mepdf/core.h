#ifndef MEPDF_CORE_H
#define MEPDF_CORE_H

#include <stdint.h>

#if defined(__GNUC__)
#define MEPDF_API __attribute__((visibility("default")))
#else
#define MEPDF_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

enum {
    MEPDF_ABI_VERSION = 1,
};

MEPDF_API uint32_t mepdf_abi_version(void);

#ifdef __cplusplus
}
#endif

#endif
