EnableExplicit

Macro trace(message)
  msg(message);
EndMacro

Procedure msg(message.s)
  Define filePath.s{1000}
  GetModuleFileName_(#Null, @filePath, 1000)
  Define path.s = GetPathPart(filePath) + "ScriptComponent.dll" + ".log"
  Define file.l = OpenFile(#PB_Any, path)
  If file <> 0    ; opens an existing file or creates one, if it does not exist yet
    FileSeek(file, Lof(file))         ; jump to the end of the file (result of Lof() is used)
    WriteStringN(file, FormatDate("%dd.%mm.%yyyy %hh:%ii:%ss", Date())+ "  " + "ScriptComponent.dll" + "  " + message)
    CloseFile(file)
  EndIf
EndProcedure


DataSection
  jsonVBS : IncludeBinary "VbsJson.vbs" 
  Data.s Chr(0);null-terminator
  jsonJS  : IncludeBinary "json2.js"
  Data.s Chr(0);null-terminator
EndDataSection 

XIncludeFile "Unsigned.pb"
XIncludeFile "Unicode.pb"
XIncludeFile "Logger.pb"
XIncludeFile "FlashRuntimeExtensions.pbi"
XIncludeFile "ScriptControl.pb"
XIncludeFile "Object.pb"


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


Structure ScriptParameters
  hwnd.l
  code.l
  vbs.l
  timeout.l
  jsonData.s
  script.s
  ctx.l
EndStructure


Procedure.s ExecuteScript(*params.ScriptParameters)
  Define request.s = Str(*params\code)
  
  trace("[" + request + "] Prepared To run script")
  
  OnErrorCall(@ErrorHandler())
  
  Define resultString.s
  
  ;Create Control
  Define *control.IScript = NewScript()
  trace("[" + request + "] Initialized ScriptComponent")
  
  Define jsonParser.s
  
  ;Set timeout
  *control\SetTimeOut(*params\timeout)
  trace("[" + request + "] ScriptComponent timeout=" + Str(*params\timeout))
  
  ;Set Script Language
  If(*params\vbs)
    *control\SetLanguage("VBScript")
    trace("[" + request + "] ScriptComponent language=VBScript")
    jsonParser = PeekS(?jsonVBS, -1, #PB_UTF16)
  Else
    *control\SetLanguage("JScript")
    trace("[" + request + "] ScriptComponent language=JScript")
    jsonParser = PeekS(?jsonJS, -1, #PB_UTF16)
  EndIf
  
  Define *parameters.objObject, jsonData.s
  *parameters = NewObject()
  jsonData = Utf8ToUnicode(*params\jsonData)
  trace("[" + request + "] ScriptComponent jsonData: " + #CRLF$ + jsonData)
  
  Define *arguments.VARIANT
  *arguments = AddMapElement(*parameters\Values(), "arguments")
  Define hRes.l = VariantInit_(*arguments)
  If #S_OK <> hRes
    trace("Failed to create BSTR");
    resultString = ErrorJSON(2, 0)
  Else
    *arguments\vt = #VT_BSTR
    *arguments\bstrVal = T_BSTR(jsonData)
    *control\AddObject("parameters", *parameters)
    ;trace("[" + request + "] ScriptComponent parser: " + #CRLF$ + jsonParser)
    
    ;Add Script to Control
    Define r.l = *control\AddCode(jsonParser)
    If r <> #S_OK
      resultString = *control\GetError()
      trace("Failed to add json parser: " + resultString)
    Else
      trace("[" + request + "] ScriptComponent loaded JSON parser")
      
      ;trace("[" + request + "] ScriptComponent script: " + #CRLF$ + Utf8ToUnicode(*params\script))
      ;Add Script to Control
      r = *control\AddCode(Utf8ToUnicode(*params\script))
      If r <> #S_OK
        resultString = *control\GetError()
        trace("Failed to execute plugin: " + resultString)
      Else
        trace("[" + request + "] ScriptComponent executed plugin")
        ;Get value of variable "result" 
        resultString.s = *control\EvalStr("result")
        trace("result = " + resultString)
      EndIf
    EndIf
    VariantClear_(*arguments)
  EndIf 
  
  ;Destroy Control
  *control\Release()
  
  ProcedureReturn resultString
EndProcedure
 
 
Procedure RunScript(*params.ScriptParameters)
  Define result.s = ExecuteScript(*params)
  Define size.l = WideCharToMultiByte_(#CP_UTF8, 0, @result, -1, 0, 0, 0, 0)
  Define eventResult.l = FREDispatchStatusEventAsync(*params\ctx, Utf8Alloc(Str(*params\code)), UnicodeToUtf8Alloc(result))
  trace (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
  FreeMemory(*params)
EndProcedure

 
;CDecl
ProcedureC.l Execute(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  trace("Invoked Execute, args size:" + Str(fromULong(argc)))

  Define result.l, length.l, async.l, jsonData.s, script.s, *string.Ascii, code.l, vbs.l, timeout.l
  
  result = FREGetObjectAsInt32(*argv\object[0], @code)
  trace("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
 
  result = FREGetObjectAsBool(*argv\object[1], @async)
  trace("result=" + ResultDescription(result, "FREGetObjectAsBool"))
  
  result = FREGetObjectAsBool(*argv\object[2], @vbs)
  trace("result=" + ResultDescription(result, "FREGetObjectAsBool"))
  
  result = FREGetObjectAsInt32(*argv\object[3], @timeout)
  trace("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsUTF8(*argv\object[4], @length, @*string)
  trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  jsonData = PeekS(*string, fromULong(length) + 1)
  
  result = FREGetObjectAsUTF8(*argv\object[5], @length, @*string)
  trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  script = PeekS(*string, fromULong(length) + 1)
  
  trace("Argument: code=" + Str(code))
  trace("Argument: async=" + Str(fromULong(async)))
  trace("Argument: timeout=" + Str(timeout))
  trace("Argument: isVBScript=" + Str(vbs))
  trace("Argument: jsonData=" + Utf8ToUnicode(jsonData))
  trace("Argument: script=" + Utf8ToUnicode(script))
  
  
  Define *params.ScriptParameters = AllocateMemory(SizeOf(ScriptParameters))
  *params\ctx = ctx
  *params\code = code
  *params\hwnd = 0 ;todo
  *params\script = script
  *params\jsonData = jsonData
  *params\vbs = vbs
  *params\timeout = timeout
  
  Define resultString.s = ErrorJSON(0, 0)
  
  If(async)
    trace("execute async")
    CreateThread(@RunScript(), *params)
  Else
    trace("execute sync")
    resultString = ExecuteScript(*params)
  EndIf

  Define resultObject.l
  Define size.l = WideCharToMultiByte_(#CP_UTF8, 0, @resultString, -1, 0, 0, 0, 0)
  
  result = FRENewObjectFromUTF8(toULong(size), UnicodeToUtf8Alloc(resultString), @resultObject)
  trace(ResultDescription(result, "FRENewObjectFromUTF8"))
  
  ProcedureReturn resultObject
EndProcedure


;CDecl
ProcedureC contextInitializer(extData.l, ctxType.s, ctx.l, *numFunctions.Long, *functions.Long)
  trace("create context: " + Str(ctx) + "=" + Utf8ToUnicode(ctxType))
  
  Define result.l
  
  ;exported extension functions count:
  Define size.l = 1 
  
  ;Array of FRENamedFunction:
  Dim f.FRENamedFunction(size - 1)
  
  ;there is no unsigned long type in PB
  setULong(*numFunctions, size)
  
  ;If you want to return a string out of a DLL, the string has to be declared as Global before using it.
  
  ;method name
  f(0)\name = Utf8Alloc("execute")
  ;function pointer
  f(0)\function = @Execute()
  
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
; CursorPosition = 253
; FirstLine = 230
; Folding = ---