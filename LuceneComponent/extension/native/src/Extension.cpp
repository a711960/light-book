#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <wchar.h>
#include <stdarg.h>

#include <malloc.h>
#include <windows.h>


#include "Extension.h"

#ifdef LOG_ENABLED
    #define DEBUG_PRINT(msg) print(msg)
    #define DEBUG_RESULT(method, result) printResult(method, result)
#else
    #define DEBUG_PRINT(msg)
    #define DEBUG_RESULT(method, result)
#endif


void print(const char * msg)
{
    if(LOG_ENABLED)
    {
        FILE *file;
        char fname[] = LOG_FILE;
        file = fopen(fname,"a");

        if(file == NULL)
        {
            return;
        }

        fprintf(file, "%s", msg);
        fprintf(file, "\n");

        fclose(file);
    }
}

void printResult(const char * method, FREResult result)
{
    char msg [1024];

    if(FRE_OK == result)
    {
        sprintf(msg, "SUCCESS FRE_OK: %s", method);
    }
    else if(FRE_NO_SUCH_NAME == result)
    {
        sprintf(msg, "ERROR FRE_NO_SUCH_NAME: %s", method);
    }
    else if(FRE_INVALID_OBJECT == result)
    {
        sprintf(msg, "ERROR FRE_INVALID_OBJECT: %s", method);
    }
    else if(FRE_TYPE_MISMATCH == result)
    {
        sprintf(msg, "ERROR FRE_TYPE_MISMATCH: %s", method);
    }
    else if(FRE_ACTIONSCRIPT_ERROR == result)
    {
        sprintf(msg, "ERROR FRE_ACTIONSCRIPT_ERROR: %s", method);
    }
    else if(FRE_INVALID_ARGUMENT == result)
    {
        sprintf(msg, "ERROR FRE_INVALID_ARGUMENT: %s", method);
    }
    else if(FRE_INVALID_ARGUMENT == result)
    {
        sprintf(msg, "ERROR FRE_INVALID_ARGUMENT: %s", method);
    }
    else if(FRE_READ_ONLY == result)
    {
        sprintf(msg, "ERROR FRE_READ_ONLY: %s", method);
    }
    else if(FRE_WRONG_THREAD == result)
    {
        sprintf(msg, "ERROR FRE_WRONG_THREAD: %s", method);
    }
    else if(FRE_ILLEGAL_STATE == result)
    {
        sprintf(msg, "ERROR FRE_ILLEGAL_STATE: %s", method);
    }
    else if(FRE_INSUFFICIENT_MEMORY == result)
    {
        sprintf(msg, "ERROR FRE_INSUFFICIENT_MEMORY: %s", method);
    }

    print(msg);
}

/*
* Private. Check strings before convertion.
*/
bool is_not_empty_strw(const wchar_t * s)
{
     return (s != NULL && wcslen(s) > 1 && wcscmp(s, L"") > 0);
}

FREObject get_null_string_as_empty(const char * resultString)
{
    FREObject stringObject;
    FREResult result;

    if(resultString != NULL && strlen(resultString) > 1)
    {
       result = FRENewObjectFromUTF8((uint32_t)strlen(resultString), (const uint8_t*)resultString, &stringObject);
    }
    else
    {
       result = FRENewObjectFromUTF8((uint32_t)strlen(""), (const uint8_t*)"", &stringObject);
    }
    DEBUG_RESULT("FRENewObjectFromUTF8: get_null_string_as_empty", result);
    return stringObject;
}

void put_object_property_int32(FREObject object, const uint8_t * propertyName, uint32_t value)
{
    char msg [1024];
    FREResult result;
    FREObject propertyValue;

    result = FRENewObjectFromUint32(value, &propertyValue);
    sprintf(msg, "FRENewObjectFromUint32: %s", propertyName);
    DEBUG_RESULT(msg, result);

    result = FRESetObjectProperty(object, propertyName, propertyValue, NULL);
    sprintf(msg, "FRESetObjectProperty: %s", propertyName);
    DEBUG_RESULT(msg, result);
}

void put_object_property_strw(FREObject object, const uint8_t * propertyName, const wchar_t * value)
{
    if(is_not_empty_strw(value))
    {
        char msg [1024];
        char * string = (char *) malloc(8192);
        wcstombs(string,  value, 8192);
        FREObject propertyValue = get_null_string_as_empty(string);
        FREResult result = FRESetObjectProperty(object, propertyName, propertyValue, NULL);
        sprintf(msg, "FRESetObjectProperty: %s", propertyName);
        DEBUG_RESULT(msg, result);
        free(string);
    }
}

/*
* Private. Returns as3 object (Boolean) for bool.
*/
FREObject get_result_as_boolean(bool value)
{
    FREObject resultObject;
    FREResult result = FRENewObjectFromBool(value, &resultObject);
    DEBUG_RESULT("FRENewObjectFromBool: get_result_as_boolean", result);
    return resultObject;
}

/*
* Private. Returns as3 object (int) for int.
*/
FREObject get_result_as_int32(int value)
{
    FREObject resultObject;
    FREResult result = FRENewObjectFromInt32(value, &resultObject);
    DEBUG_RESULT("FRENewObjectFromInt32: get_result_as_int32", result);
    return resultObject;
}

/*
* hid_close (hid_device *device)
*/
FREObject test(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    DEBUG_PRINT("test");

    return get_result_as_boolean(true);
}

void contextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctions, const FRENamedFunction** functions)
{
    char msg [1024];
    sprintf(msg, "contextInitializer: %s", (char *)ctxType);
    DEBUG_PRINT(msg);

    *numFunctions = 1;

    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * (*numFunctions));

    func[0].name = (const uint8_t*) "test";
    func[0].functionData = NULL;
    func[0].function = &test;

    *functions = func;
}

void contextFinalizer(FREContext ctx)
{
    DEBUG_PRINT("contextFinalizer");
    //close open device if any
    return;
}

void initializer(void** extData, FREContextInitializer* ctxInitializer, FREContextFinalizer* ctxFinalizer)
{
    DEBUG_PRINT("initializer");
    *ctxInitializer = &contextInitializer;
    *ctxFinalizer = &contextFinalizer;
}

//The runtime calls this function when it unloads an extension. However, the runtime does not guarantee that it will
//unload the extension or call FREFinalizer().
void finalizer(void* extData)
{
    DEBUG_PRINT("finalizer");
    return;
}
