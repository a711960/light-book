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


Procedure ErrorHandler()
  Define ErrorMessage$ = "A program error was detected:" + Chr(13) 
  ErrorMessage$ + Chr(13)
  ErrorMessage$ + "Error Message:   " + ErrorMessage()      + Chr(13)
  ErrorMessage$ + "Error Code:      " + Str(ErrorCode())    + Chr(13)  
  ErrorMessage$ + "Code Address:    " + Str(ErrorAddress()) + Chr(13)
  trace(ErrorMessage$)
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

Structure Tag
  line_begin.l
  line_size.l
  value_begin.l
  value_size.l
EndStructure

Structure TagKeyValue
  value.l
  valueSize.l
  key.l
  keySize.l
EndStructure


Procedure RunExifTool(*params.ExifParameters)
  Define key.b = Asc(":")
  
  Define Compiler.i = RunProgram(*params\executable, *params\parameters, *params\workingDir, #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  Define *stdout = AllocateMemory(*params\maxOutput)
  If Compiler
    Define offset.l = 0
    Define size.l = 0
    While ProgramRunning(Compiler)
      Sleep_(100)
      size = AvailableProgramOutput(Compiler)
      If(size > 0)
        ReadProgramData(Compiler, *stdout + offset, size)
        offset = offset + size
      EndIf
    Wend
    
    Define exitCode.l = ProgramExitCode(Compiler)
    Debug "exitCode = " + Str(exitCode)
    
    If exitCode <> 0
      ProcedureReturn 
    EndIf
    
    Debug "output size: " + Str(offset)
    Dim outlines.Tag(100)
    Dim tags.TagKeyValue(100)
    Define i.l, n.l, prev.l
    Define tagName.s
    
    For i = 1 To offset-1
      Define b1.b = PeekB(*stdout + i - 1)
      Define b2.b = PeekB(*stdout + i)
      
      If(b1 = Asc(#CR$) And b2 = Asc(#LF$))
        outlines(n)\line_begin = *stdout + prev
        outlines(n)\line_size = i - prev
        Define m.l
        For m = 1 To (i - prev)
          Define c.b = PeekB(*stdout + prev + m)
          If(c = key)
            Break
          EndIf
        Next
        outlines(n)\value_begin = *stdout + (prev + m + 2)
        outlines(n)\value_size = i - (prev + m + 2)
        
        tags(n)\key = outlines(n)\line_begin
        tags(n)\keySize = m
        n = n + 1
        prev = i
      EndIf
    Next
    CloseProgram(Compiler) ; Close the connection to the program
  EndIf
  
  Debug "Line count: " + Str(n)
  

  Define status.l, ucsd.l, ucsm.l, *name, name.s, sub.s, matches.s
  ucsd = ucsdet_open_49(@status)
  Debug "ucsd(" + Str(ucsd) + ") status(" + Str(status) + ")"
  
  Define l.l, value_begin.l, value_size.l
  For l=0 To n - 1
    
    value_begin = outlines(l)\value_begin
    value_size = outlines(l)\value_size
    
   
    Debug "start " + Str(value_begin)
    Debug "end " + Str(value_begin + value_size)
    
    Debug Chr(PeekA(value_begin))
    Debug PeekS(value_begin, value_size, #PB_Ascii)
    Debug PeekS(tags(l)\key, tags(l)\keySize, #PB_Ascii)
    
    ucsdet_setText_49(ucsd, value_begin, value_size, @status)
    Debug "ucsdet_setText_49 status(" + Str(status) + ")"
    
    ucsm = ucsdet_detect_49(ucsd, @status)
    Debug "ucsm(" + Str(ucsm) + ") status(" + Str(status) + ")"
    
    If ucsm <> 0
      *name = ucsdet_getName_49(ucsm, @status)
      name = PeekS(*name, -1, #PB_Ascii)
      ; convert To name
      Define *target = AllocateMemory(4000)
      Define converted.l
      converted = ucnv_convert_49(@"utf-8", *name, *target, 4000, value_begin, value_size, @status)
      Debug "ucnv_convert_49 (" + Str(status) + ")"
      Debug "converted size = " + Str(converted)
      tags(l)\valueSize = converted
      Define lines.s
      If converted > 0
        lines = PeekS(*target, -1, #PB_UTF8)
        tags(l)\value = AllocateMemory(converted)
        CopyMemory(*target, tags(l)\value, converted)
      EndIf
      FreeMemory(*target)
      Debug "converted: '" + lines + "'"
    Else
      name = "unknown"
    EndIf
    Debug "ucsdet_getName_49 [" + name + "] status(" + Str(status) + ")"
  Next
  
  ucsdet_close_49(ucsd)  
  
  Define subresult.s = ""
  For l=0 To n - 1
    If(tags(l)\valueSize > 0)
      subresult = subresult + PeekS(tags(l)\key, tags(l)\keySize, #PB_Ascii) + ":" + PeekS(tags(l)\value, tags(l)\valueSize - 1, #PB_Ascii)
      FreeMemory(tags(l)\value)
    EndIf
  Next
  
  FreeMemory(*stdout)
  
  trace(subresult)
  
  Define eventResult.l = FREDispatchStatusEventAsync(*params\ctx, AsciiAlloc(Str(*params\code)), AsciiAlloc(subresult))
  trace (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
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
; CursorPosition = 18
; Folding = ---