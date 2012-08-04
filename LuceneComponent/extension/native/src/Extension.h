#define LOG_ENABLED false

#ifdef _WIN32
    //force using mingw <stdint.h>, see FlashRuntimeExtensions.h
    #undef WIN32
    #include "../../../../Common/include/FlashRuntimeExtensions.h"
    #define EXPORT __declspec(dllexport)
    #define LOG_FILE "c:/hidapi.log"
#endif

//export c-functions
#ifdef __cplusplus
extern "C" {
#endif

EXPORT void initializer(void** extData, FREContextInitializer* ctxInitializer, FREContextFinalizer* ctxFinalizer);
EXPORT void finalizer(void* extData);

#ifdef __cplusplus
}
#endif

