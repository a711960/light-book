#ifndef UNICODE
#define UNICODE
#endif

#ifndef _UNICODE
#define _UNICODE
#endif

#include <windows.h>

#ifdef _WIN32
    //force using mingw <stdint.h>, see FlashRuntimeExtensions.h
    #undef WIN32
    #include "../../../../Common/include/FlashRuntimeExtensions.h"
    #define EXPORT __declspec(dllexport)
    #define LOG_FILE "c:/hidapi.log"
#endif

#define LOG_ENABLED false

//export c-functions
#ifdef __cplusplus
extern "C" {
#endif

EXPORT void initializer(void** extData, FREContextInitializer* ctxInitializer, FREContextFinalizer* ctxFinalizer);
EXPORT void finalizer(void* extData);

#ifdef __cplusplus
}
#endif

