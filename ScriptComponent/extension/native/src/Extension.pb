EnableExplicit

DataSection
  jsonVBS : IncludeBinary "VbsJson.vbs" 
  Data.s Chr(0)
  jsonJS  : IncludeBinary "json2.js"
  Data.s Chr(0)
EndDataSection 

;#LOG_FILE = "C:\pureair.log"

XIncludeFile "Unsigned.pb"
XIncludeFile "Unicode.pb"
XIncludeFile "Logger.pb"
XIncludeFile "FlashRuntimeExtensions.pbi"
XIncludeFile "ScriptControl.pb"
XIncludeFile "Object.pb"

Global *log.Logger

ProcedureDLL AttachProcess(Instance)
  ;- This procedure is called once, when the program loads the library
  ;  for the first time. All init stuffs can be done here (but not DirectX init)
  Define processID.l = GetCurrentProcessId_()
  
  *log = New_Logger("ScriptComponent.dll")
  
  *log\info(#CRLF$)
  *log\info(#CRLF$)
  *log\info("----------------------------------------------------------------")
  *log\info("AttachProcess: " + Str(processID) + ", instance = " + Str(Instance))
EndProcedure


ProcedureDLL DetachProcess(Instance)
  ;- Called when the program release (free) the DLL
  *log\info("DetachProcess: " + Str(Instance))
  *log\info("----------------------------------------------------------------")
  FreeMemory(*log)
EndProcedure


;- Both are called when a thread in a program call Or release (free) the DLL
ProcedureDLL AttachThread(Instance)
  *log\Debug("AttachThread: " + Str(Instance))
EndProcedure


ProcedureDLL DetachThread(Instance)
  *log\Debug("DetachThread: " + Str(Instance))
EndProcedure


Procedure LogError()
   Define error.l
   error = GetLastError_()
   If error
      Define *Memory, length.l, err_msg$
      *Memory = AllocateMemory(255)
      length = FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, #Null, error, 0, *Memory, 255, #Null)
      If length > 1 ; Some error messages are "" + Chr (13) + Chr (10)... stoopid M$... :(
         err_msg$ = PeekS(*Memory, length - 2)
      Else
         err_msg$ = "Unknown error!"
      EndIf
      FreeMemory(*Memory)
      *log\error(err_msg$)
   EndIf
EndProcedure 

Structure ExecuteParameters
  hwnd.l
  code.l
  vbs.l
  timeout.l
  jsonData.s
  script.s
  ctx.l
EndStructure

Procedure ErrorHandler()
   *log\error("Unhandled error: " + ErrorMessage())
EndProcedure
 
;-T_BSTR
Procedure helpSysAllocString(*Value)
  ProcedureReturn SysAllocString_(*Value)
EndProcedure
Prototype.l ProtoSysAllocString(Value.p-unicode)

Global T_BSTR.ProtoSysAllocString = @helpSysAllocString()


Procedure.s ExecuteScript(*params.ExecuteParameters)
  Define request.s = Str(*params\code)
  
  *log\info("[" + request + "] Prepared To run script")
  
  OnErrorCall(@ErrorHandler())
  
  ;Create Control
  Define *control.IScript = NewScript()
  *log\info("[" + request + "] Initialized ScriptComponent")
  
  Define jsonParser.s
  
  ;Set timeout
  *control\SetTimeOut(*params\timeout)
  *log\info("[" + request + "] ScriptComponent timeout=" + Str(*params\timeout))
  
  ;Set Script Language
  If(*params\vbs)
    *control\SetLanguage("VBScript")
    *log\info("[" + request + "] ScriptComponent language=VBScript")
    jsonParser = PeekS(?jsonVBS, -1, #PB_UTF16)
  Else
    *control\SetLanguage("JScript")
    *log\info("[" + request + "] ScriptComponent language=JScript")
    jsonParser = PeekS(?jsonJS, -1, #PB_UTF16)
  EndIf
  
  Define *parameters.objObject, jsonData.s
  *parameters = NewObject()
  jsonData = Utf8ToUnicode(*params\jsonData)
  *log\info("[" + request + "] ScriptComponent jsonData: " + #CRLF$ + jsonData)
  
  Define *arguments.VARIANT
  *arguments = AddMapElement(*parameters\Values(), "arguments")
  Define hRes.l = VariantInit_(*arguments)
  If #S_OK = hRes
    *arguments\vt = #VT_BSTR
    *arguments\bstrVal = T_BSTR(jsonData)
   
    *control\AddObject("parameters", *parameters)
  Else
    *log\error("Failed to create BSTR");
  EndIf 

  
  ;*log\info("[" + request + "] ScriptComponent parser: " + #CRLF$ + jsonParser)
  
  ;Add Script to Control
  Define r.l = *control\AddCode(jsonParser)
  If r <> #S_OK
    *log\error("Failed to add json parser: " + *control\GetError())
  Else
    *log\info("[" + request + "] ScriptComponent loaded JSON parser")
    
    ;*log\info("[" + request + "] ScriptComponent script: " + #CRLF$ + Utf8ToUnicode(*params\script))
    ;Add Script to Control
    r = *control\AddCode(Utf8ToUnicode(*params\script))
    If r <> #S_OK
      *log\error("Failed to execute plugin: " + *control\GetError())
    Else
      *log\info("[" + request + "] ScriptComponent executed plugin")
    EndIf
  EndIf
  
  VariantClear_(*arguments)
 
  ;Get value of variable "result" 
  Define result.s = *control\EvalStr("result")
  *log\info("result = " + result)
  
  ;Destroy Control
  *control\Release()
  
  ProcedureReturn result
EndProcedure
 
 
Procedure RunScript(*params.ExecuteParameters)
  Define result.s = ExecuteScript(*params)
  Define eventResult.l = FREDispatchStatusEventAsync(*params\ctx, asGlobal(Str(*params\code)), asGlobal(result))
  *log\Debug (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
EndProcedure

 
;CDecl
ProcedureC.l Execute(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  *log\info("Invoked Execute")
  *log\info("Method args size: " + Str(fromULong(argc)))

  Define result.l, length.l, async.l, jsonData.s, script.s, *string.Ascii, code.l, isVBScript.l, timeout.l
  
  result = FREGetObjectAsInt32(*argv\object[0], @code)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
 
  result = FREGetObjectAsBool(*argv\object[1], @async)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsBool"))
  
  result = FREGetObjectAsBool(*argv\object[2], @isVBScript)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsBool"))
  
  result = FREGetObjectAsInt32(*argv\object[3], @timeout)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsUTF8(*argv\object[4], @length, @*string)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  jsonData = PeekS(*string, fromULong(length) + 1)
  
  result = FREGetObjectAsUTF8(*argv\object[5], @length, @*string)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  script = PeekS(*string, fromULong(length) + 1)
  
  *log\info("Argument: code=" + Str(code))
  *log\info("Argument: async=" + Str(fromULong(async)))
  *log\info("Argument: timeout=" + Str(timeout))
  *log\info("Argument: isVBScript=" + Str(fromULong(isVBScript)))
  *log\info("Argument: jsonData=" + Utf8ToUnicode(jsonData))
  *log\info("Argument: script=" + Utf8ToUnicode(script))
  
  
  Define *params.ExecuteParameters = AllocateMemory(SizeOf(ExecuteParameters))
  *params\ctx = ctx
  *params\code = code
  *params\hwnd = 0 ;todo
  *params\script = script
  *params\jsonData = jsonData
  *params\vbs = isVBScript
  *params\timeout = timeout
  
  Define resultString.s = "ok"
  If(async)
    *log\info("execute async")
    CreateThread(@RunScript(), *params)
  Else
    *log\info("execute sync")
    resultString = ExecuteScript(*params)
  EndIf

  Define resultObject.l
  result = FRENewObjectFromUTF8(toULong(Len(resultString)), asGlobal(resultString), @resultObject)
  *log\Debug(ResultDescription(result, "FRENewObjectFromUTF8"))
  
  ProcedureReturn resultObject
EndProcedure


;CDecl
ProcedureC contextInitializer(extData.l, ctxType.s, ctx.l, *numFunctions.Long, *functions.Long)
  *log\info("create context: " + Str(ctx) + "=" + Utf8ToUnicode(ctxType))
  
  Define result.l
  
  ;exported extension functions count:
  Define size.l = 1 
  
  ;Array of FRENamedFunction:
  Dim f.FRENamedFunction(size - 1)
  
  ;there is no unsigned long type in PB
  setULong(*numFunctions, size)
  
  ;If you want to return a string out of a DLL, the string has to be declared as Global before using it.
  
  ;method name
  f(0)\name = asGlobal("execute")
  ;function pointer
  f(0)\function = @Execute()
  
  *functions\l = @f()
  
  *log\info("create context complete");
EndProcedure 


;CDecl
ProcedureC contextFinalizer(ctx.l)
  *log\info("dispose context: " + Str(ctx))
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
; CursorPosition = 232
; FirstLine = 199
; Folding = ---