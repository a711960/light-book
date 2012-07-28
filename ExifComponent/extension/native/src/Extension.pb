EnableExplicit

Import "Kernel32.lib"
  ;   DWORD WINAPI GetShortPathName(
  ;     __in   LPCTSTR lpszLongPath,
  ;     __out  LPTSTR lpszShortPath,
  ;     __in   DWORD cchBuffer
  ;   );
  GetShortPathNameW(path.l, shortpath.l, size.l)
EndImport

XIncludeFile "..\..\..\..\Common\include\Unsigned.pb"
XIncludeFile "..\..\..\..\Common\include\FlashRuntimeExtensions.pbi"
XIncludeFile "..\..\..\..\Common\include\Unicode.pb"
XIncludeFile "..\..\..\..\Common\include\icuin.pbi"
XIncludeFile "..\..\..\..\Common\include\icuuc.pbi"

Macro trace(message)
  ;msg(message);
EndMacro

Procedure msg(message.s)
  Define filePath.s{1000}
  GetModuleFileName_(#Null, @filePath, 1000)
  Define path.s = GetPathPart(filePath) + "ExifComponent.dll" + ".log"
  Define file.l = OpenFile(#PB_Any, path)
  If file <> 0    ; opens an existing file or creates one, if it does not exist yet
    FileSeek(file, Lof(file))         ; jump to the end of the file (result of Lof() is used)
    WriteStringN(file, FormatDate("%dd.%mm.%yyyy %hh:%ii:%ss", Date())+ "  " + "ExifComponent.dll" + "  " + message)
    CloseFile(file)
  EndIf
EndProcedure


Procedure.s GetError()
   Define error.l,  err_msg$
   error = GetLastError_()
   err_msg$ = "no last error"
   If error
      Define *Memory, length.l
      *Memory = AllocateMemory(255)
      length = FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, #Null, error, 0, *Memory, 255, #Null)
      If length > 1 ; Some error messages are "" + Chr (13) + Chr (10)... stoopid M$... :(
         err_msg$ = PeekS(*Memory, length - 2)
      Else
      err_msg$ = "unknown"
      EndIf
      FreeMemory(*Memory)
    EndIf
    ProcedureReturn err_msg$
EndProcedure 


Procedure.l CreateErrorString(message.s)
    Define result.l, resultObject.l
    Define error.s = "error: " + message
    trace(error)
    result = FRENewObjectFromUTF8(toULong(Len(error)), AsciiAlloc(error), @resultObject)
    trace(ResultDescription(result, "FRENewObjectFromUTF8"))
    ProcedureReturn resultObject
EndProcedure


ProcedureDLL AttachProcess(Instance)
  ;- This procedure is called once, when the program loads the library
  ;  for the first time. All init stuffs can be done here (but not DirectX init)
  Define processID.l = GetCurrentProcessId_()

  trace(#CRLF$)
  trace(#CRLF$)
  trace("----------------------------------------------------------------")
  trace("AttachProcess: " + Str(processID) + ", instance = " + Str(Instance))
EndProcedure


ProcedureDLL DetachProcess(Instance)
  ;- Called when the program release (free) the DLL
  trace("DetachProcess: " + Str(Instance))
  trace("----------------------------------------------------------------")
EndProcedure


;- Both are called when a thread in a program call Or release (free) the DLL
ProcedureDLL AttachThread(Instance)
  trace("AttachThread: " + Str(Instance))
EndProcedure


ProcedureDLL DetachThread(Instance)
  trace("DetachThread: " + Str(Instance))
EndProcedure


Structure ExifParameters
  executable.s  ;path to exiftool.exe
  workingDir.s  ;process working directory
  parameters.s  ;exiftool parameters
  timeout.l     ;execution timeout
  maxOutput.l   ;buffer size
  ctx.l         ;extension context
  code.l        ;request code
EndStructure


Procedure.l GetStdout(executable.s, parameters.s, workingDir.s, flags.l, maxOutput.l)
  Define program.i = RunProgram(executable, "-s " + parameters, workingDir, flags)
  If program
    Define *stdout = AllocateMemory(maxOutput)
    Define offset.l, size.l
    
    While ProgramRunning(program)
      Sleep_(100)
      size = AvailableProgramOutput(program)
      If(size > 0 And offset + size <= maxOutput)
        ReadProgramData(program, *stdout + offset, size)
        offset = offset + size
      EndIf
    Wend
    
    Define exitCode.l = ProgramExitCode(program)
    CloseProgram(program) ; Close the connection to the program
    
    If exitCode = 0
      Define *result = AllocateMemory(offset)
      CopyMemory(*stdout, *result, offset)
      FreeMemory(*stdout)
      ProcedureReturn *result
    Else
      FreeMemory(*stdout)
      ProcedureReturn 0
    EndIf
  Else
    ProcedureReturn 0
  EndIf
EndProcedure


Procedure.s ParseTags(*stdout, file.s)
  Define i.l, m.l, prev.l, size.l
  Define status.l, ucsd.l, ucsm.l, *name
  Define result.s = ""
  
  ucsd = ucsdet_open_49(@status)
  
  If ucsd <> 0
      size = MemorySize(*stdout)
      For i = 1 To size - 1
        If(PeekB(*stdout + i - 1) = 13 And PeekB(*stdout + i) = 10)
           Define line_begin.l = *stdout + prev

           For m = 1 To (i - prev)
               If(PeekB(*stdout + prev + m) = 58) ; Asc(":")
                    Break
               EndIf
           Next
           
           Define value_begin.l = *stdout + (prev + m + 2)
           Define value_size.l = i - (prev + m + 2)
           Define keySize.l = m
           
           prev = i
           
           ucsdet_setText_49(ucsd, value_begin, value_size, @status)
           If status <> 0
               Continue
           EndIf
           
           ucsm = ucsdet_detect_49(ucsd, @status)
           If ucsm = 0
               Continue
           EndIf
          
           *name = ucsdet_getName_49(ucsm, @status)
           Define *target = AllocateMemory(4096)
           Define converted.l = ucnv_convert_49(@"utf-8", *name, *target, 4000, value_begin, value_size, @status)
           If converted > 0
                result = result + PeekS(line_begin, keySize, #PB_Ascii) + ":" + PeekS(*target, converted - 1, #PB_Ascii)
           EndIf
           FreeMemory(*target)
       EndIf
      Next
      ucsdet_close_49(ucsd)
      If Len(result) > 1
          result = result + #CRLF$ + "MD5:" + MD5FileFingerprint(file) 
      EndIf
      trace(result)
      ProcedureReturn result
  Else
      ProcedureReturn ""
  EndIf
EndProcedure
  

Procedure RunExifTool(*params.ExifParameters)
    Define eventResult.l
    
    Define stdout.i = GetStdout(*params\executable, *params\parameters, *params\workingDir, #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide, *params\maxOutput)
  
    If stdout
        Define result.s = ParseTags(stdout, *params\parameters)
        If Len(result) > 1
            eventResult = FREDispatchStatusEventAsync(*params\ctx, AsciiAlloc(Str(*params\code)), AsciiAlloc(result))
            trace (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
        Else
            eventResult = FREDispatchStatusEventAsync(*params\ctx, AsciiAlloc(Str(*params\code)), AsciiAlloc("error: failed to extract metadata"))
            trace (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
        EndIf
    Else
        eventResult = FREDispatchStatusEventAsync(*params\ctx, AsciiAlloc(Str(*params\code)), AsciiAlloc("error: execution failed"))
        trace (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
    EndIf
  FreeMemory(*params)
EndProcedure

 
;CDecl
ProcedureC.l Execute(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  trace("Invoked Execute, args size:" + Str(fromULong(argc)))

  Define result.l, length.l, maxOutput.l, parameters.s, *string.Ascii, code.l, executable.s, timeout.l, workingDir.s
  
  result = FREGetObjectAsInt32(*argv\object[0], @code)
  trace("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsInt32(*argv\object[1], @maxOutput)
  trace("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsInt32(*argv\object[2], @timeout)
  trace("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsUTF8(*argv\object[3], @length, @*string)
  trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  executable = PeekS(*string, fromULong(length) + 1)
  
  result = FREGetObjectAsUTF8(*argv\object[4], @length, @*string)
  trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  parameters = PeekS(*string, fromULong(length) + 1)
  
  result = FREGetObjectAsUTF8(*argv\object[5], @length, @*string)
  trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  workingDir = PeekS(*string, fromULong(length) + 1)
  
  trace("Argument: code=" + Str(code))
  trace("Argument: maxOutput=" + Str(maxOutput))
  trace("Argument: timeout=" + Str(timeout))
  trace("Argument: executable=" + executable)
  trace("Argument: parameters=" + parameters)
  trace("Argument: workingDir=" + workingDir)
  
  
  Define *params.ExifParameters = AllocateMemory(SizeOf(ExifParameters))
  *params\ctx = ctx
  *params\code = code
  *params\executable = executable
  *params\parameters = parameters
  *params\workingDir = workingDir
  *params\maxOutput = maxOutput
  
  
  CreateThread(@RunExifTool(), *params)
  
  Define resultObject.l
 
  result = FRENewObjectFromBool(toULong(1), @resultObject)
  trace(ResultDescription(result, "FRENewObjectFromBool"))
  
  ProcedureReturn resultObject
EndProcedure

;CDecl
ProcedureC.l GetShortPath(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  trace("Invoked GetShortPath, args size:" + Str(fromULong(argc)))
  
  Define length.l, *path.Ascii, result.l
  
  result = FREGetObjectAsUTF8(*argv\object[0], @length, @*path)
  If(result <> #FRE_OK)
    ProcedureReturn CreateErrorString(ResultDescription(result, "FREGetObjectAsUTF8"))
  EndIf
   
  Define result.l, resultObject.l, resultString.s, size.i, pathSize.l, *longpath.Unicode, *shortpath.Unicode
    
  size = MultiByteToWideChar_(#CP_UTF8, 0, *path, -1, 0, 0)
  If(0 = size)
    ProcedureReturn CreateErrorString("MultiByteToWideChar failed(size), " + GetError())
  EndIf
  
  *longpath.Unicode = AllocateMemory(size * 2)
  If(0 = *longpath)
    ProcedureReturn CreateErrorString("Failed to allocate memory, " + GetError())
  EndIf
  
  size = MultiByteToWideChar_(#CP_UTF8, 0 , *path, -1, *longpath, size)
  If(0 = size)
    FreeMemory(*longpath)
    ProcedureReturn CreateErrorString("MultiByteToWideChar failed, " + GetError())
  EndIf
  
  pathSize = GetShortPathNameW(*longpath, #Null, 0)
  If(0 = pathSize)
    FreeMemory(*longpath)
    ProcedureReturn CreateErrorString("GetShortPathNameW failed (size), " + GetError())
  EndIf
  
  *shortpath = AllocateMemory(pathSize * 2 + 1)
  If(0 = *shortpath)
    FreeMemory(*longpath)
    ProcedureReturn CreateErrorString("Failed to allocate memory, " + GetError())
  EndIf
  
  pathSize = GetShortPathNameW(*longpath, *shortpath, size)
  If(0 = pathSize)
    FreeMemory(*longpath)
    FreeMemory(*shortpath)
    ProcedureReturn CreateErrorString("GetShortPathNameW failed, " + GetError())
  EndIf
  
  FreeMemory(*longpath)
    
  size = WideCharToMultiByte_(#CP_UTF8, 0, *shortpath, pathSize, 0, 0, 0, 0)
  If(0 = size)
    FreeMemory(*shortpath)
    ProcedureReturn CreateErrorString("WideCharToMultiByte failed(size), " + GetError())
  EndIf

  Define *result = AllocateMemory(size)
  If(0 = *result)
    FreeMemory(*shortpath)
    ProcedureReturn CreateErrorString("Failed to allocate memory, " + GetError())
  EndIf
  
  If(0 = WideCharToMultiByte_(#CP_UTF8, 0 , *shortpath, pathSize, *result, size, 0, 0))
    FreeMemory(*shortpath)
    ProcedureReturn CreateErrorString("WideCharToMultiByte failed, " + GetError())
  EndIf
     
  trace(PeekS(*result, size, #PB_UTF8))
  
  result = FRENewObjectFromUTF8(toULong(size), *result, @resultObject)
  If(result <> #FRE_OK)
    FreeMemory(*shortpath)
    ProcedureReturn CreateErrorString(ResultDescription(result, "FREGetObjectAsUTF8"))
  EndIf
  
  ProcedureReturn resultObject
EndProcedure



;CDecl
ProcedureC contextInitializer(extData.l, ctxType.s, ctx.l, *numFunctions.Long, *functions.Long)
  trace("create context: " + Str(ctx) + "=" + Utf8ToUnicode(ctxType))
  
  Define result.l
  
  ;exported extension functions count:
  Define size.l = 2 
  
  ;Array of FRENamedFunction:
  Dim f.FRENamedFunction(size - 1)
  
  ;there is no unsigned long type in PB
  setULong(*numFunctions, size)
  
  ;If you want to return a string out of a DLL, the string has to be declared as Global before using it.
  
  ;method name
  f(0)\name = AsciiAlloc("execute")
  ;function pointer
  f(0)\function = @Execute()
  
  f(1)\name = AsciiAlloc("GetShortPath")
  ;function pointer
  f(1)\function = @GetShortPath()
  
  *functions\l = @f()
  
  trace("create context complete");
EndProcedure 


;CDecl
ProcedureC contextFinalizer(ctx.l)
  trace("dispose context: " + Str(ctx))
EndProcedure 


;CDecl
ProcedureCDLL initializer(extData.l, *ctxInitializer.Long, *ctxFinalizer.Long)
  *ctxInitializer\l = @contextInitializer()
  *ctxFinalizer\l = @contextFinalizer()
EndProcedure 


;CDecl
;this method is never called on Windows...
ProcedureCDLL finalizer(extData.l)
  ;do nothing
EndProcedure 

; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 183
; FirstLine = 171
; Folding = ---