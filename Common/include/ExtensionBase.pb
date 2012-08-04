EnableExplicit

#ERROR_ASSERTION_FAILURE = $29C

XIncludeFile "..\..\..\..\Common\include\FlashRuntimeExtensions.pbi"

;-- Dll
ProcedureDLL AttachProcess(Instance)
  ;- This procedure is called once, when the program loads the library
  ;  for the first time. All init stuffs can be done here (but not DirectX init)
EndProcedure


ProcedureDLL DetachProcess(Instance)
  ;- Called when the program release (free) the DLL
EndProcedure


;- Both are called when a thread in a program call Or release (free) the DLL
ProcedureDLL AttachThread(Instance)
EndProcedure

ProcedureDLL DetachThread(Instance)
EndProcedure


;-- Debug
Procedure msg(message.s)
    Define handle.l = 0
    Define grabbed.l = 0
    While(grabbed = 0)
        handle = CreateMutex_(#Null, #True, @"book-log")  
        If(#ERROR_ALREADY_EXISTS = handle)
            ;try
            handle = OpenMutex_(#SYNCHRONIZE, #False, @"book-log")
            If(#ERROR_FILE_NOT_FOUND = handle)
                Continue
            ElseIf (handle <> 0)
                grabbed = 1
            Else
                ;failure
                Break
            EndIf
        ElseIf(handle = 0)
            ;failure
            Break
        Else
            ;granted
            grabbed = 1
        EndIf
    Wend
    
      
    Define filePath.s{1000}
    GetModuleFileName_(#Null, @filePath, 1000)
    Define path.s = GetPathPart(filePath) + "light-book.log"
    Define file.l = OpenFile(#PB_Any, path)
    If file <> 0    ; opens an existing file or creates one, if it does not exist yet
        FileSeek(file, Lof(file))         ; jump to the end of the file (result of Lof() is used)
        WriteStringN(file, FormatDate("%dd.%mm.%yyyy %hh:%ii:%ss", Date())+ "  " + #TRACE_FILENAME + "  " + message)
        CloseFile(file)
    EndIf
    
    If(grabbed)
        ReleaseMutex_(handle)
        CloseHandle_(handle)
    EndIf
EndProcedure

Macro trace(message)
  CompilerIf #TRACE_ENABLED
      msg(message);
  CompilerEndIf
EndMacro

Procedure ErrorHandler()
  Define ErrorMessage$
  ErrorMessage$ = "A program error was detected:" + Chr(13) 
  ErrorMessage$ + Chr(13)
  ErrorMessage$ + "Error Message:   " + ErrorMessage()      + Chr(13)
  ErrorMessage$ + "Error Code:      " + Str(ErrorCode())    + Chr(13)  
  ErrorMessage$ + "Code Address:    " + Str(ErrorAddress()) + Chr(13)
 
  If ErrorCode() = #PB_OnError_InvalidMemory   
    ErrorMessage$ + "Target Address:  " + Str(ErrorTargetAddress()) + Chr(13)
  EndIf
 
  If ErrorLine() = -1
    ErrorMessage$ + "Sourcecode line: Enable OnError lines support to get code line information." + Chr(13)
  Else
    ErrorMessage$ + "Sourcecode line: " + Str(ErrorLine()) + Chr(13)
    ErrorMessage$ + "Sourcecode file: " + ErrorFile() + Chr(13)
  EndIf
 
  ErrorMessage$ + Chr(13)
  ErrorMessage$ + "Register content:" + Chr(13)
 
  CompilerSelect #PB_Compiler_Processor 
    CompilerCase #PB_Processor_x86
      ErrorMessage$ + "EAX = " + Str(ErrorRegister(#PB_OnError_EAX)) + Chr(13)
      ErrorMessage$ + "EBX = " + Str(ErrorRegister(#PB_OnError_EBX)) + Chr(13)
      ErrorMessage$ + "ECX = " + Str(ErrorRegister(#PB_OnError_ECX)) + Chr(13)
      ErrorMessage$ + "EDX = " + Str(ErrorRegister(#PB_OnError_EDX)) + Chr(13)
      ErrorMessage$ + "EBP = " + Str(ErrorRegister(#PB_OnError_EBP)) + Chr(13)
      ErrorMessage$ + "ESI = " + Str(ErrorRegister(#PB_OnError_ESI)) + Chr(13)
      ErrorMessage$ + "EDI = " + Str(ErrorRegister(#PB_OnError_EDI)) + Chr(13)
      ErrorMessage$ + "ESP = " + Str(ErrorRegister(#PB_OnError_ESP)) + Chr(13)
 
    CompilerCase #PB_Processor_x64
      ErrorMessage$ + "RAX = " + Str(ErrorRegister(#PB_OnError_RAX)) + Chr(13)
      ErrorMessage$ + "RBX = " + Str(ErrorRegister(#PB_OnError_RBX)) + Chr(13)
      ErrorMessage$ + "RCX = " + Str(ErrorRegister(#PB_OnError_RCX)) + Chr(13)
      ErrorMessage$ + "RDX = " + Str(ErrorRegister(#PB_OnError_RDX)) + Chr(13)
      ErrorMessage$ + "RBP = " + Str(ErrorRegister(#PB_OnError_RBP)) + Chr(13)
      ErrorMessage$ + "RSI = " + Str(ErrorRegister(#PB_OnError_RSI)) + Chr(13)
      ErrorMessage$ + "RDI = " + Str(ErrorRegister(#PB_OnError_RDI)) + Chr(13)
      ErrorMessage$ + "RSP = " + Str(ErrorRegister(#PB_OnError_RSP)) + Chr(13)
      ErrorMessage$ + "Display of registers R8-R15 skipped."         + Chr(13)
 
    CompilerCase #PB_Processor_PowerPC
      ErrorMessage$ + "r0 = " + Str(ErrorRegister(#PB_OnError_r0)) + Chr(13)
      ErrorMessage$ + "r1 = " + Str(ErrorRegister(#PB_OnError_r1)) + Chr(13)
      ErrorMessage$ + "r2 = " + Str(ErrorRegister(#PB_OnError_r2)) + Chr(13)
      ErrorMessage$ + "r3 = " + Str(ErrorRegister(#PB_OnError_r3)) + Chr(13)
      ErrorMessage$ + "r4 = " + Str(ErrorRegister(#PB_OnError_r4)) + Chr(13)
      ErrorMessage$ + "r5 = " + Str(ErrorRegister(#PB_OnError_r5)) + Chr(13)
      ErrorMessage$ + "r6 = " + Str(ErrorRegister(#PB_OnError_r6)) + Chr(13)
      ErrorMessage$ + "r7 = " + Str(ErrorRegister(#PB_OnError_r7)) + Chr(13)
      ErrorMessage$ + "Display of registers r8-R31 skipped."       + Chr(13)
  CompilerEndSelect
 
  MessageRequester("Fatal Error", ErrorMessage$)
EndProcedure
 


;-- Error handling
Procedure.s GetErrorMessage()
   Define error.l,  err_msg$
   error = GetLastError_()
   err_msg$ = "no last error"
   If error
      Define *Memory, length.l
      *Memory = AllocateMemory(255)
      If(*Memory = 0)
          trace("Error: AllocateMemory")
          RaiseError(#ERROR_ASSERTION_FAILURE)
      EndIf
      length = FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, #Null, error, 0, *Memory, 255, #Null)
      If length > 1 ; Some error messages are "" + Chr (13) + Chr (10)... stoopid M$... :(
         err_msg$ = PeekS(*Memory, length - 2)
      Else
      err_msg$ = ""
      EndIf
      FreeMemory(*Memory)
    EndIf
    ProcedureReturn err_msg$
EndProcedure 


;PB supports only unsigned byte (Ascii) and unsigned int (Unicode)
;unsigned long is not supported
;-- Unsigned

Procedure.q getULong(*source.Long)
   ;- Reads 4 bytes from the specified memory address,
   ;  and returns the value as *unsigned* integer
   ;  (minimum = 0, maximum = 4294967295).

   If *source\l < 0
      ProcedureReturn *source\l + $100000000
   Else
      ProcedureReturn *source\l
   EndIf
EndProcedure
 
Procedure setULong(*target.Long, source.q)
   ;- Writes an *unsigned* integer of 4 bytes size
   ;  to the specified memory address.

   If source >= 0 And source <= $FFFFFFFF
      If source > $7FFFFFFF
         *target\l = source - $100000000
      Else
         *target\l = source
      EndIf
   EndIf
EndProcedure

Procedure.q fromULong(source.l)
  ProcedureReturn getULong(@source)
EndProcedure
 
Procedure.l toULong(source.q)
  Define result.l
  setULong(@result, source)
  ProcedureReturn result
EndProcedure

;-- Unicode
#CP_UTF8 = 65001

Procedure.s Utf8ToUnicode(string.s)
  ;- Converts UCS2 to UTF8
  Define size.i, result.s
  size = MultiByteToWideChar_(#CP_UTF8, 0, @string, -1, 0, 0)
  If(size = 0)
      trace("Error: MultiByteToWideChar_")
      RaiseError(#ERROR_ASSERTION_FAILURE)
  EndIf
  result = Space(size * 2)+ Chr(0)
  size = MultiByteToWideChar_(#CP_UTF8, 0 , @string, -1, @result, size)
  If(size = 0)
      trace("Error: MultiByteToWideChar_")
      RaiseError(#ERROR_ASSERTION_FAILURE)
  EndIf
  ProcedureReturn result 
EndProcedure


Procedure.s UnicodeToUtf8(string.s)
  ;- Converts UTF8 to UCS2
  Define size.i, result.s
  size = WideCharToMultiByte_(#CP_UTF8, 0, @string, -1, 0, 0, 0, 0)
  If(size  = 0)
      trace("Error: WideCharToMultiByte_")
      RaiseError(#ERROR_ASSERTION_FAILURE)
  EndIf
  result = Space(size + 1)
  Define ret.l = WideCharToMultiByte_(#CP_UTF8, 0 , @string, -1, @result, size, 0, 0)
  If(ret = 0)
      trace("Error: WideCharToMultiByte_")
      RaiseError(#ERROR_ASSERTION_FAILURE)
  EndIf
  ProcedureReturn result
EndProcedure

; If you want to return a string out of a DLL, the string has to be declared as Global before using it.

Procedure.l AsciiAlloc(string.s)
  ;- Converts UCS2 to Ascii
  Define *result.Ascii = AllocateMemory(Len(string) + 1)
  If(*result = 0)
      trace("Error: AllocateMemory")
      RaiseError(#ERROR_ASSERTION_FAILURE)
  EndIf
  PokeS(*result, string, -1, #PB_Ascii)
  ProcedureReturn *result
EndProcedure

Procedure.l UnicodeToUtf8Alloc(string.s)
  ;- Converts UTF8 to UCS2
  Define size.l = WideCharToMultiByte_(#CP_UTF8, 0, @string, -1, 0, 0, 0, 0)
  If(size = 0)
      trace("Error: WideCharToMultiByte_")
      RaiseError(#ERROR_ASSERTION_FAILURE)
  EndIf
  Define *result.Ascii = AllocateMemory(size)
  If(*result = 0)
      trace("Error: AllocateMemory")
      RaiseError(#ERROR_ASSERTION_FAILURE)
  EndIf
  Define ret.l = WideCharToMultiByte_(#CP_UTF8, 0 , @string, -1, *result, size, 0, 0)
  If(ret = 0)
      trace("Error: WideCharToMultiByte_")
      RaiseError(#ERROR_ASSERTION_FAILURE)
  EndIf
  ProcedureReturn *result
EndProcedure

;-- Extension utils

Procedure.l GetInt32(object.l)
    Define result.l
    Define ret.l = FREGetObjectAsInt32(object, @result)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FREGetObjectAsInt32"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn result
EndProcedure

Procedure.l GetArgInt32(index.l, argc.l, *argv.FREObjectArray)
    If(index >= argc)
        trace("Error: index out of bounds index=" + Str(index) + ", size=" + Str(argc))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn GetInt32(*argv\object[index])
EndProcedure

Procedure.s GetString(object.l)
    Define length.l , *result.Ascii
    Define ret.l = FREGetObjectAsUTF8(object, @length, @*result)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FREGetObjectAsUTF8"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn PeekS(*result, fromULong(length))
EndProcedure

Procedure.s GetArgString(index.l, argc.l, *argv.FREObjectArray)
    If(index >= argc)
        trace("Error: index out of bounds index=" + Str(index) + ", size=" + Str(argc))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn GetString(*argv\object[index])
EndProcedure

Procedure.l GetArrayLen(arr.l)
    Define result.l
    Define ret.l = FREGetArrayLength(arr, @result)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FREGetArrayLength"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn result
EndProcedure

Procedure.l GetArgArrayLen(index.l, argc.l, *argv.FREObjectArray)
    If(index >= argc)
        trace("Error: index out of bounds index=" + Str(index) + ", size=" + Str(argc))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn GetArrayLen(*argv\object[index])
EndProcedure

Procedure.l GetArrayItem(arr.l, index.l)
    Define result.l
    Define ret.l = FREGetArrayElementAt(arr, index, @result)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FREGetArrayElementAt"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn result
EndProcedure

Procedure.l GetArgArrayItem(index.l, argc.l, *argv.FREObjectArray, itemIndex.l)
    If(index >= argc)
        trace("Error: index out of bounds index=" + Str(index) + ", size=" + Str(argc))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn GetArrayItem(*argv\object[index], itemIndex)
EndProcedure

Procedure.l GetNewBool(bool.l)
    Define resultObject.l
    Define ret.l = FRENewObjectFromBool(toULong(bool), @resultObject)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FRENewObjectFromBool"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn resultObject
EndProcedure

Procedure.l GetNewStringUTF8(message.s)
    Define ret.l, resultObject.l
    ret = FRENewObjectFromUTF8(toULong(Len(message)), AsciiAlloc(message), @resultObject)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FRENewObjectFromUTF8"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn resultObject
EndProcedure

Procedure.l GetNewStringWC(message.s)
    Define size.l = WideCharToMultiByte_(#CP_UTF8, 0, @message, -1, 0, 0, 0, 0)
    If(size = 0)
        trace("Error: WideCharToMultiByte  " + GetErrorMessage())
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    Define ret.l, resultObject.l
    ret = FRENewObjectFromUTF8(toULong(size), UnicodeToUtf8Alloc(message), @resultObject)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FRENewObjectFromUTF8"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn resultObject
EndProcedure

Procedure DispatchEvent(ctx.l, code.s, level.s)
    Define ret.l
    ret = FREDispatchStatusEventAsync(ctx, AsciiAlloc(code), AsciiAlloc(level))
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FREDispatchStatusEventAsync"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
EndProcedure

Procedure DispatchEventEx(ctx.l, code.l, level.l)
    Define ret.l
    ret = FREDispatchStatusEventAsync(ctx, code, level)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FREDispatchStatusEventAsync"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
EndProcedure

Procedure.l GetBool(object.l)
    Define result.l
    Define ret.l = FREGetObjectAsBool(object, @result)
    If(ret <> #FRE_OK)
        trace("Error:" + ResultDescription(ret, "FREGetObjectAsBool"))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn result
EndProcedure

Procedure.l GetArgBool(index.l, argc.l, *argv.FREObjectArray)
    If(index >= argc)
        trace("Error: index out of bounds index=" + Str(index) + ", size=" + Str(argc))
        RaiseError(#ERROR_ASSERTION_FAILURE)
    EndIf
    ProcedureReturn GetBool(*argv\object[index])
EndProcedure



; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 152
; FirstLine = 33
; Folding = ------
; EnableXP