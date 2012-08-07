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
#endif
#include "../../../../Common/include/FlashRuntimeExtensions.h"

void print(const char * logfile, const char * filename, long line, const char * funcname, const char * msg, ...);
void printResult(const char * logfile, const char * filename, long line, const char * funcname, const char * method, FREResult result);

#define LOG_FILE "c:/hidapi.log"
#define LOG_ENABLED

#ifdef LOG_ENABLED
    #define DEBUG_PRINT(filename, line, funcname, pattern, ...)         print(LOG_FILE, filename, line, funcname, pattern, ##__VA_ARGS__)
    #define DEBUG_RESULT(filename, line, funcname, method, result)      printResult(LOG_FILE, filename, line, funcname, method, result)
#else
    #define DEBUG_PRINT(filename, line, funcname, pattern, ...)
    #define DEBUG_RESULT(filename, line, funcname, method, result)
#endif

//export c-functions
#ifdef __cplusplus
extern "C" {
#endif

#define EXPORT __declspec(dllexport)
EXPORT void initializer(void** extData, FREContextInitializer* ctxInitializer, FREContextFinalizer* ctxFinalizer);
EXPORT void finalizer(void* extData);

#ifdef __cplusplus
}
#endif

